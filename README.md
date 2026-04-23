# TomoTexture — macOS launcher

A macOS launcher that runs the Windows build of [**TomoTexture** by Alfonso Mallozzi](https://github.com/AlfonsoMallozzi/TomoTexture) directly from its bundled `.pyc` modules, without recompilation or porting.

All credit for the TomoTexture application itself goes to **Alfonso Mallozzi**. This repo contains only the macOS launcher wrapper — it does **not** redistribute Alfonso's binaries. The setup script downloads the upstream Windows release from Alfonso's GitHub releases page and extracts the required bytecode locally on your machine.

## Requirements

- macOS
- Python 3.14 (the bundled `.pyc` magic number matches 3.14 exactly; other versions will refuse to load)
  - Install via: `brew install python@3.14`
- [Ryujinx](https://github.com/Ryujinx/Ryujinx) with Tomodachi Life save data under `~/Library/Application Support/Ryujinx/bis/user/save/...`

## Install (one-liner)

Open **Terminal** (Cmd+Space → type "Terminal" → Enter) and paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/zachmtz08/tomotexture-port/main/install.sh)"
```

This will:
1. Clone the repo to `~/tomotexture-port`.
2. Create a Python 3.14 `.venv` and install `numpy`, `Pillow`, `PyYAML`, `zstandard`.
3. Download `TomoTexture1.1.exe` from [Alfonso's release page](https://github.com/AlfonsoMallozzi/TomoTexture/releases/tag/release) and extract it.
4. Drop a `TomoTexture.command` shortcut on your Desktop.

When it finishes, double-click `TomoTexture.command` on your Desktop.

### Manual install (if you prefer)

```bash
git clone https://github.com/zachmtz08/tomotexture-port.git
cd tomotexture-port
./setup.sh
```

## Launch

Double-click `TomoTexture.command` (on your Desktop if you used the one-liner, or inside the repo folder otherwise), or run:

```bash
./TomoTexture.command
```

## First-run setup in the app

When the app opens, you'll see two Browse buttons:

- **Save Location** → point this at your Ryujinx save folder. On macOS this lives at `~/Library/Application Support/Ryujinx/bis/user/save/<YOUR_SAVE_ID>/` (the folder containing `0/`, `1/`, and `SAVE BACKUP/`). In the file dialog, press **Cmd+Shift+G** and paste the path (macOS hides `Library` in Finder by default).
- **Backup Location** → any folder where you want backups to live. A safe choice is a folder in `~/Documents/` so backups survive if you ever reinstall Ryujinx.

## How it works

The Windows app contains a hardcoded path literal `%APPDATA%\Ryujinx\bis\user\save\...` and resolves it with `os.path.expandvars`. On macOS:

- `os.path.expandvars` is `posixpath.expandvars`, which only handles `$VAR` / `${VAR}` — `%VAR%` passes through unchanged.
- Backslashes aren't path separators on POSIX.

`launcher.py` monkey-patches `os.path.expandvars` to use `ntpath.expandvars` (which handles `%VAR%`), sets `APPDATA` to `~/Library/Application Support`, and replaces backslashes with forward slashes in the result. The bundled app then resolves its save path to the correct macOS Ryujinx location with zero changes to the original code.

## License

The launcher code in this repo (`launcher.py`, `TomoTexture.command`, `setup.sh`, `install.sh`, `requirements.txt`, this README) is released under the MIT License.

**TomoTexture itself** is Alfonso Mallozzi's work. Its license was not specified at the upstream repo at the time of writing — use at your own discretion. This repo does not redistribute any upstream binaries.
