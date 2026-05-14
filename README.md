# TomoTexture for macOS

**A drag-and-drop install that lets Mac users run [TomoTexture](https://github.com/AlfonsoMallozzi/TomoTexture) — Alfonso Mallozzi's texture editor for *Tomodachi Life: Living The Dream* UGC saves — on top of Ryujinx.**

TomoTexture was built for Windows. This repo packages a thin macOS launcher into a self-contained `.app` that runs the original Windows build's bytecode directly, with a small patch so it finds your Ryujinx save folder. **No upstream code is hosted here**: the app downloads Alfonso's official release on first launch.

> **Credit:** All credit for TomoTexture itself goes to **Alfonso Mallozzi**. This project only ships the macOS launcher wrapper.

---

## Requirements

- **macOS 11 or newer** on **Apple Silicon (M1, M2, M3, M4...)**.
- Intel Macs are not supported — see [For developers](#for-developers) if you want to build a x86_64 version yourself; in practice, running Ryujinx + a Switch save through this tool isn't viable on Intel hardware regardless.

## Install

1. **Download** [`TomoTexture.dmg`](https://github.com/zachmtz08/tomotexture-port/releases/latest) from the latest release.
2. **Double-click the `.dmg`** to open it.
3. **Drag `TomoTexture` onto the `Applications` folder** in the same window.
4. **Eject the disk image** (right-click the `TomoTexture` drive on your Desktop → Eject) and open `Applications`.
5. **Right-click `TomoTexture` → Open** → in the dialog, click **Open**.

   > **⚠ This only happens ONCE.** macOS shows this because TomoTexture isn't signed with a paid Apple Developer ID — same as Handbrake, OpenEmu, and other free, unsigned apps. After this first time, double-clicking just works.
   >
   > **If your macOS version doesn't show an "Open" button** (only "Done"):
   > - Open **System Settings → Privacy & Security**
   > - Scroll to the **Security** section
   > - Click **Open Anyway** next to the TomoTexture warning
   > - Right-click TomoTexture → Open again, and confirm

6. The first launch shows a small progress window while it downloads TomoTexture from Alfonso's GitHub (~34 MB) and sets it up. After that, every launch opens straight into the app.

---

## First-time setup inside the app

When the app opens for the first time, it'll ask for two folders:

### Save Location
Point this at your Ryujinx save folder for Tomodachi Life. On macOS it lives at:

```
~/Library/Application Support/Ryujinx/bis/user/save/<YOUR_SAVE_ID>/
```

`<YOUR_SAVE_ID>` is a 16-digit number (commonly `0000000000000001`). It's the folder that contains subfolders named `0/`, `1/`, and (after first use) `SAVE BACKUP/`.

**How to navigate to it in the Browse dialog:**
1. In the Browse dialog, press **Cmd + Shift + G** (Go to Folder).
2. Paste this path: `~/Library/Application Support/Ryujinx/bis/user/save`
3. Press Enter.
4. Pick the numbered folder inside (usually `0000000000000001`).

> macOS hides `~/Library` in Finder by default — that's why you need Cmd+Shift+G.

### Backup Location
Any folder where you want backups stored. A safe choice is a folder in `~/Documents/` so backups survive if you ever reinstall Ryujinx. If you don't have one, create `~/Documents/TomoTexture-Backups` first in Finder, then select it.

---

## Troubleshooting

**"Cannot be opened because Apple cannot check it for malicious software"** (or *"...because it is from an unidentified developer"*) — This is macOS Gatekeeper blocking unsigned downloads. See step 5 above (right-click → Open). You only need to do it once.

**"App is damaged and can't be opened. You should move it to the Trash."** — Same Gatekeeper check, more aggressively worded. Use the right-click → Open path above. If that doesn't work, open Terminal and run:
```
xattr -dr com.apple.quarantine /Applications/TomoTexture.app
```
then try opening it normally. (This removes the quarantine flag macOS adds to internet downloads.)

**First-launch progress window stalls or shows an error** — Quit the app, make sure your internet is working, and re-open. The app stores its download under `~/Library/Application Support/TomoTexture/`. Deleting that folder and reopening forces a clean re-download.

**App opens but says "Slot Mismatch Detected"** — This is the app warning you that your save slots and your existing backups don't match (e.g., you added new items since the last backup). Not an error. Click through it; if you want it to stop appearing, take a fresh in-app backup.

**App can't find Library folder in the Browse dialog** — Use Cmd+Shift+G to paste the path directly. macOS hides `~/Library` from Finder by default.

**Re-installing or updating** — Drag the new `TomoTexture.app` from a fresh `.dmg` into `/Applications`, replacing the old one. Your downloaded runtime under `~/Library/Application Support/TomoTexture/` is reused, so updates don't re-download.

---

## For developers

### Building the .app locally

You need Python 3.14 (Homebrew or [python.org](https://www.python.org/downloads/macos/) — both work).

```bash
git clone https://github.com/zachmtz08/tomotexture-port.git
cd tomotexture-port
python3.14 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python setup.py py2app --arch=arm64
open dist/TomoTexture.app
```

The build is arm64-only because numpy 2.x and recent Pillow stopped shipping universal2 wheels — a universal2 build would silently break on Intel anyway. If you want to build for x86_64 specifically, swap `--arch=arm64` for `--arch=x86_64` and run on (or under Rosetta on) an Intel-capable machine.

### How the launcher works

The Windows TomoTexture app contains hardcoded path literals like `%APPDATA%\Ryujinx\bis\user\save\...` and resolves them with `os.path.expandvars`. On macOS:

- `os.path.expandvars` is `posixpath.expandvars`, which only handles `$VAR` / `${VAR}` — it leaves `%VAR%` untouched.
- Backslashes aren't path separators on POSIX; they're literal filename characters.

`app_main.py` monkey-patches `os.path.expandvars` to use `ntpath.expandvars` (which handles `%VAR%`), sets `APPDATA` to `~/Library/Application Support`, and replaces backslashes with forward slashes in the result. The bundled app then resolves its save paths to the correct macOS Ryujinx location with zero changes to the original code.

Python 3.14 is required because the upstream `.pyc` files were compiled against 3.14's bytecode magic number; `runpy.run_path` will refuse to load them under any other minor version. The `.app` bundles its own Python 3.14 interpreter via py2app, so end users don't need to install anything.

### CI

`.github/workflows/release.yml` builds the arm64 `.app`, packages it into a `.dmg`, and attaches it to the GitHub Release on every `v*` tag push. To cut a release:

```bash
git tag v2.0.0
git push --tags
```

You can also trigger a build manually from the Actions tab (`workflow_dispatch`) — useful for verifying the workflow without cutting a real tag.

### Legacy install scripts

The Terminal-based installer (`install.sh`, `setup.sh`, `TomoTexture-Installer.command`, `TomoTexture.command`) lives in [`legacy/`](legacy/) for now in case anyone is mid-install with the old flow. They will be removed in a future release.

---

## License

The launcher code in this repo is released under the MIT License — see [LICENSE](LICENSE).

**TomoTexture itself** is Alfonso Mallozzi's work and is downloaded from his [official release page](https://github.com/AlfonsoMallozzi/TomoTexture/releases/tag/release) at first launch. Its license was not specified upstream at the time of writing — use at your own discretion. This repo does not redistribute any upstream binaries.
