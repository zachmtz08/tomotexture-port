"""TomoTexture macOS — py2app entry point.

On first launch (or when the runtime cache is missing), shows a small Tk
progress window while downloading Alfonso Mallozzi's Windows release,
unpacking the PyInstaller bundle, and caching the .pyc bytecode under
~/Library/Application Support/TomoTexture/app_runtime/.

Subsequent launches skip the bootstrap and hand off straight to the upstream
app. We don't redistribute the upstream binary because its repo has no license.
"""
import os
import ssl
import sys
import ntpath
import runpy
import shutil
import threading
import traceback
import urllib.request
from pathlib import Path

import certifi

UPSTREAM_URL = (
    "https://github.com/AlfonsoMallozzi/TomoTexture/releases/download/release/"
    "TomoTexture1.1.exe"
)
EXPECTED_SIZE_HINT = 36 * 1024 * 1024  # ~34 MB; only used for indeterminate fallback

APP_SUPPORT = Path.home() / "Library" / "Application Support" / "TomoTexture"
RUNTIME_DIR = APP_SUPPORT / "app_runtime"
EXE_PATH = APP_SUPPORT / "TomoTexture1.1.exe"
EXTRACT_DIR = APP_SUPPORT / "TomoTexture1.1.exe_extracted"
REQUIRED_RUNTIME_FILES = ("__main__.pyc", "swizzle.pyc", "tex_format.pyc")


def _runtime_ready() -> bool:
    return all((RUNTIME_DIR / name).is_file() for name in REQUIRED_RUNTIME_FILES)


def _download_with_progress(url: str, dest: Path, on_progress) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    # python.org's bundled Python doesn't trust the system cert store on its
    # own; pass certifi's bundle explicitly so the .app works on a fresh Mac.
    ctx = ssl.create_default_context(cafile=certifi.where())
    with urllib.request.urlopen(url, context=ctx) as resp:
        total = int(resp.headers.get("Content-Length") or EXPECTED_SIZE_HINT)
        on_progress(0, total)
        with open(tmp, "wb") as out:
            done = 0
            while True:
                chunk = resp.read(64 * 1024)
                if not chunk:
                    break
                out.write(chunk)
                done += len(chunk)
                on_progress(done, total)
    tmp.replace(dest)


def _unpack_pyinstaller_exe(exe: Path, into: Path) -> None:
    from pyinstxtractor_ng import PyInstArchive

    if into.exists():
        shutil.rmtree(into)
    into.parent.mkdir(parents=True, exist_ok=True)

    # PyInstArchive writes the extracted folder next to the .exe in CWD.
    cwd = Path.cwd()
    work = into.parent
    try:
        os.chdir(work)
        archive = PyInstArchive(str(exe))
        if not archive.open():
            raise RuntimeError("could not open the upstream .exe")
        if not archive.checkFile():
            raise RuntimeError("upstream file is not a valid PyInstaller archive")
        if not archive.getCArchiveInfo():
            raise RuntimeError("could not read PyInstaller archive header")
        archive.parseTOC()
        # one_dir=False: upstream is a one-file PyInstaller bundle.
        archive.extractFiles(one_dir=False)
        archive.close()
    finally:
        os.chdir(cwd)


def _install_runtime(set_status, set_progress) -> None:
    APP_SUPPORT.mkdir(parents=True, exist_ok=True)

    if not EXE_PATH.exists():
        set_status("Downloading TomoTexture from Alfonso's release page...")
        _download_with_progress(UPSTREAM_URL, EXE_PATH, set_progress)

    set_status("Unpacking the Windows bundle...")
    set_progress(None, None)
    _unpack_pyinstaller_exe(EXE_PATH, EXTRACT_DIR)

    set_status("Setting up runtime files...")
    src_main = EXTRACT_DIR / "app.pyc"
    src_swizzle = EXTRACT_DIR / "PYZ.pyz_extracted" / "swizzle.pyc"
    src_tex = EXTRACT_DIR / "PYZ.pyz_extracted" / "tex_format.pyc"
    missing = [p for p in (src_main, src_swizzle, src_tex) if not p.is_file()]
    if missing:
        raise RuntimeError(
            "Upstream archive layout changed — missing expected files: "
            + ", ".join(str(p.name) for p in missing)
            + f". Extracted contents are in {EXTRACT_DIR}."
        )

    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src_main, RUNTIME_DIR / "__main__.pyc")
    shutil.copy2(src_swizzle, RUNTIME_DIR / "swizzle.pyc")
    shutil.copy2(src_tex, RUNTIME_DIR / "tex_format.pyc")

    try:
        shutil.rmtree(EXTRACT_DIR)
    except OSError:
        pass


def _show_progress_and_install() -> None:
    import tkinter as tk
    from tkinter import ttk, messagebox

    root = tk.Tk()
    root.title("TomoTexture — First Launch Setup")
    root.geometry("460x170")
    root.resizable(False, False)

    ttk.Label(root, text="Setting up TomoTexture", font=("Helvetica", 15, "bold")).pack(pady=(18, 4))

    status_var = tk.StringVar(value="Preparing...")
    ttk.Label(root, textvariable=status_var).pack(pady=(0, 10))

    progress = ttk.Progressbar(root, length=400, mode="determinate")
    progress.pack(pady=(0, 6))

    detail_var = tk.StringVar(value="")
    ttk.Label(root, textvariable=detail_var, foreground="#666").pack()

    state = {"error": None}

    def set_status(msg):
        root.after(0, lambda: status_var.set(msg))

    def set_progress(done, total):
        def _apply():
            if done is None or total is None:
                progress.stop()
                progress.config(mode="indeterminate")
                progress.start(40)
                detail_var.set("")
                return
            progress.stop()
            progress.config(mode="determinate", maximum=total, value=done)
            detail_var.set(f"{done / 1024 / 1024:.1f} MB of {total / 1024 / 1024:.1f} MB")
        root.after(0, _apply)

    def worker():
        try:
            _install_runtime(set_status, set_progress)
        except Exception as exc:
            state["error"] = exc
            traceback.print_exc()
        finally:
            root.after(0, root.destroy)

    threading.Thread(target=worker, daemon=True).start()
    root.mainloop()

    if state["error"] is not None:
        err_root = tk.Tk()
        err_root.withdraw()
        messagebox.showerror(
            "TomoTexture — setup failed",
            f"Couldn't finish first-launch setup:\n\n{state['error']}\n\n"
            "Check your internet connection and try again. If this keeps happening, "
            "open an issue at github.com/zachmtz08/tomotexture-port/issues",
        )
        err_root.destroy()
        sys.exit(1)


def _install_windows_path_patch() -> None:
    """Make the upstream app's hardcoded %APPDATA%\\Ryujinx\\... literals resolve
    to the macOS Ryujinx save folder.

    The upstream code calls os.path.expandvars on Windows-style paths. On POSIX,
    os.path.expandvars only handles $VAR / ${VAR}, and backslashes are literal
    filename characters. Swap in ntpath.expandvars (handles both forms), set
    APPDATA, and rewrite backslashes to forward slashes after expansion.
    """
    os.environ.setdefault("APPDATA", str(Path.home() / "Library" / "Application Support"))

    _orig = os.path.expandvars

    def _expandvars(s):
        if not isinstance(s, (str, bytes)):
            return _orig(s)
        out = ntpath.expandvars(s)
        if isinstance(out, str):
            out = out.replace("\\", "/")
        elif isinstance(out, bytes):
            out = out.replace(b"\\", b"/")
        return out

    os.path.expandvars = _expandvars


def main() -> None:
    if sys.version_info[:2] != (3, 14):
        # Bundled Python should always be 3.14 — guard anyway for dev runs.
        sys.stderr.write(
            f"TomoTexture: requires Python 3.14 (upstream .pyc magic); got {sys.version}\n"
        )
        sys.exit(1)

    if not _runtime_ready():
        _show_progress_and_install()

    if not _runtime_ready():
        sys.stderr.write("TomoTexture: install incomplete; runtime files missing.\n")
        sys.exit(1)

    sys.path.insert(0, str(RUNTIME_DIR))
    _install_windows_path_patch()
    runpy.run_path(str(RUNTIME_DIR / "__main__.pyc"), run_name="__main__")


if __name__ == "__main__":
    main()
