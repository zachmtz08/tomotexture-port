# TomoTexture for macOS

**A one-click installer that lets Mac users run [TomoTexture](https://github.com/AlfonsoMallozzi/TomoTexture) — Alfonso Mallozzi's texture editor for Tomodachi Life UGC saves — on top of Ryujinx.**

TomoTexture was built for Windows. This repo is a thin wrapper that runs the original Windows build's bytecode directly on macOS, with a small launcher patch so it finds your Ryujinx save folder. **No code from TomoTexture is hosted here**: the installer downloads the official release from Alfonso's GitHub when you set things up.

> **Credit:** All credit for TomoTexture itself goes to **Alfonso Mallozzi**. This project only ships the macOS launcher wrapper.

---

## Quick install (no Terminal experience needed)

1. **Download** [**TomoTexture-Installer.zip**](https://github.com/zachmtz08/tomotexture-port/releases/latest) from the latest release.
2. **Double-click the zip** to unzip — you'll get a file named `TomoTexture-Installer.command`.
3. **Right-click** (or Control-click) that file → **Open** → click **Open** in the dialog that appears.
   - Why right-click? macOS blocks unsigned downloaded files by default. Right-click → Open is the standard way to bypass it. You only need to do this once per file.
4. A Terminal window opens. **Press Enter** when it asks, and follow the prompts. The installer will:
   - Install Xcode Command Line Tools if missing (Apple's installer dialog appears — click Install)
   - Install Homebrew if missing (asks for your Mac password)
   - Install Python 3.14 if missing
   - Download TomoTexture from Alfonso's release page
   - Set everything up
   - Put a **TomoTexture.command** shortcut on your Desktop
5. When you see **"All done!"**, close the Terminal window.
6. **Double-click TomoTexture.command on your Desktop** to launch the app.

That's it. From now on, you only need step 6.

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

**"Cannot be opened because it is from an unidentified developer"** — This is macOS Gatekeeper blocking unsigned downloads. Right-click (or Control-click) the file → **Open** → **Open**. One-time per file.

**"Python 3.14 is required" error** — Open Terminal and run `brew install python@3.14`, then re-run the installer.

**App opens but says "Slot Mismatch Detected"** — This is the app warning you that your save slots and your existing backups don't match (e.g., you added new items since the last backup). Not an error. Click through it; if you want it to stop appearing, take a fresh in-app backup.

**App can't find Library folder in the Browse dialog** — Use Cmd+Shift+G to paste the path directly. macOS hides `~/Library` from Finder by default.

**Installer is stuck on "Waiting for Xcode Command Line Tools install to finish..."** — The Apple installer is running in the background and can take 10-20 minutes. Don't close the Terminal window. If you accidentally cancelled the Apple dialog, run `xcode-select --install` in a new Terminal and accept the dialog when it appears.

**Re-installing or updating** — Just run the installer again. It detects existing installs and updates them in place.

---

## For developers

### Terminal one-liner install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/zachmtz08/tomotexture-port/main/install.sh)"
```

### Manual install

Assumes you already have `git`, Homebrew, and Python 3.14:

```bash
git clone https://github.com/zachmtz08/tomotexture-port.git
cd tomotexture-port
./setup.sh
./TomoTexture.command
```

### How the launcher works

The Windows TomoTexture app contains hardcoded path literals like `%APPDATA%\Ryujinx\bis\user\save\...` and resolves them with `os.path.expandvars`. On macOS:

- `os.path.expandvars` is `posixpath.expandvars`, which only handles `$VAR` / `${VAR}` — it leaves `%VAR%` untouched.
- Backslashes aren't path separators on POSIX; they're literal filename characters.

`launcher.py` monkey-patches `os.path.expandvars` to use `ntpath.expandvars` (which handles `%VAR%`), sets `APPDATA` to `~/Library/Application Support`, and replaces backslashes with forward slashes in the result. The bundled app then resolves its save paths to the correct macOS Ryujinx location with zero changes to the original code.

Python 3.14 is required because the bundled `.pyc` files were compiled against 3.14's bytecode magic number; `runpy.run_path` will refuse to load them under any other minor version.

---

## License

The launcher code in this repo (`launcher.py`, `TomoTexture.command`, `setup.sh`, `install.sh`, `requirements.txt`, `README.md`) is released under the MIT License — see [LICENSE](LICENSE).

**TomoTexture itself** is Alfonso Mallozzi's work and is downloaded from his [official release page](https://github.com/AlfonsoMallozzi/TomoTexture/releases/tag/release) at install time. Its license was not specified upstream at the time of writing — use at your own discretion. This repo does not redistribute any upstream binaries.
