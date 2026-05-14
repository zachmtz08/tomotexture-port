"""TomoTexture macOS launcher.

Loads the original Windows PyInstaller bundle's .pyc bytecode directly
(Python 3.14 magic matches, so no recompilation/decompilation needed) and
patches the Windows-specific default save path to the macOS Ryujinx location.
"""
import os
import os.path
import ntpath
import sys
import runpy
from pathlib import Path

# Python 3.14 is pinned because the bundled .pyc files carry that version's
# magic number; runpy.run_path will refuse to load them under any other minor.
# Use a raise rather than assert — assert is stripped under python -O.
if sys.version_info[:2] != (3, 14):
    raise RuntimeError(
        f"TomoTexture requires Python 3.14 (bundled .pyc magic); got {sys.version}"
    )

HERE = Path(__file__).parent.resolve()
RUNTIME = HERE / "app_runtime"

sys.path.insert(0, str(RUNTIME))

mac_ryujinx_root = Path.home() / "Library" / "Application Support"
os.environ.setdefault("APPDATA", str(mac_ryujinx_root))

# The bundled app calls os.path.expandvars on literals like
# "%APPDATA%\\Ryujinx\\bis\\user\\save\\...". On POSIX, os.path.expandvars is
# posixpath.expandvars, which does not expand %VAR% — so the env override alone
# is inert. Swap in ntpath.expandvars (handles both %VAR% and $VAR) and
# normalize backslashes, which are literal filename chars on macOS.
_orig_expandvars = os.path.expandvars


def _expandvars(s):
    if not isinstance(s, (str, bytes)):
        return _orig_expandvars(s)
    out = ntpath.expandvars(s)
    if isinstance(out, str):
        out = out.replace("\\", "/")
    elif isinstance(out, bytes):
        out = out.replace(b"\\", b"/")
    return out


os.path.expandvars = _expandvars

runpy.run_path(str(RUNTIME / "__main__.pyc"), run_name="__main__")
