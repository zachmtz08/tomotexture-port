#!/bin/bash
# TomoTexture macOS installer.
# Bootstraps Xcode Command Line Tools, Homebrew, and Python 3.14 as needed,
# then clones the repo and runs setup.sh.
#
# Usage (from a macOS Terminal):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/zachmtz08/tomotexture-port/main/install.sh)"
#
# Also invoked by the double-click bootstrap (TomoTexture-Installer.command).

set -euo pipefail

INSTALL_DIR="$HOME/tomotexture-port"
REPO_URL="https://github.com/zachmtz08/tomotexture-port.git"

banner() { printf '\n\033[1;34m========================================\n  %s\n========================================\033[0m\n\n' "$1"; }
say()    { printf '\033[1;34m->\033[0m %s\n' "$1"; }
ok()     { printf '\033[1;32mOK:\033[0m %s\n' "$1"; }
warn()   { printf '\033[1;33m!\033[0m  %s\n' "$1" >&2; }
die()    { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

banner "TomoTexture for macOS — Installer"

cat <<'INTRO'
This installer will set up TomoTexture by Alfonso Mallozzi to run on macOS.
It may need to install the following on your Mac (skipped if already present):

  1. Xcode Command Line Tools  (Apple, required for git)
  2. Homebrew                  (package manager)
  3. Python 3.14               (required by the app)
  4. python-tk@3.14            (Tk bindings; the app's UI needs them)

You may be prompted for your password or to click Install in a dialog.
Press Enter to continue, or close this window to cancel.
INTRO
read -r _ </dev/tty || true

# --- Step 1: Xcode Command Line Tools (gives us git) ------------------------

have_git() { command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1; }

if ! have_git; then
    banner "Installing Xcode Command Line Tools"
    say "A dialog box should appear. Click Install and wait for it to finish."
    say "This can take 10-20 minutes depending on your internet speed."
    xcode-select --install 2>/dev/null || true

    # Poll until git works. Cap at 60 minutes.
    local_start=$(date +%s)
    while ! have_git; do
        if (( $(date +%s) - local_start > 3600 )); then
            die "Xcode Command Line Tools install didn't finish within 60 minutes. Try installing manually with: xcode-select --install"
        fi
        printf '.'
        sleep 5
    done
    printf '\n'
    ok "Xcode Command Line Tools installed"
else
    ok "git already installed"
fi

# --- Step 2: Homebrew -------------------------------------------------------

have_brew() { command -v brew >/dev/null 2>&1; }

if ! have_brew; then
    banner "Installing Homebrew"
    say "You may be prompted for your Mac password. Type it and press Enter."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for this session (Apple Silicon vs Intel)
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    have_brew || die "Homebrew install finished but brew is not on PATH. Open a new Terminal and run this installer again."
    ok "Homebrew installed"
else
    ok "Homebrew already installed"
fi

# --- Step 3: Python 3.14 ----------------------------------------------------

if ! command -v python3.14 >/dev/null 2>&1; then
    banner "Installing Python 3.14"
    brew install python@3.14
    # Homebrew's python@X.Y formulae aren't auto-linked; ensure the binary is findable.
    if ! command -v python3.14 >/dev/null 2>&1; then
        PY_PREFIX="$(brew --prefix python@3.14)"
        export PATH="$PY_PREFIX/bin:$PATH"
    fi
    command -v python3.14 >/dev/null 2>&1 || die "Python 3.14 installed but not on PATH. Run: brew link --force python@3.14"
    ok "Python 3.14 installed"
else
    ok "Python 3.14 already installed"
fi

# --- Step 3b: Tk bindings for Python 3.14 -----------------------------------
# Homebrew's python@3.14 does NOT bundle _tkinter; the app's UI imports it and
# crashes on launch with "ModuleNotFoundError: No module named '_tkinter'"
# unless python-tk@3.14 is installed alongside it.

if ! python3.14 -c "import _tkinter" >/dev/null 2>&1; then
    banner "Installing Tk bindings (python-tk@3.14)"
    brew install python-tk@3.14
    python3.14 -c "import _tkinter" >/dev/null 2>&1 || die "python-tk@3.14 installed but Python still can't import _tkinter. Try: brew reinstall python-tk@3.14"
    ok "Tk bindings installed"
else
    ok "Tk bindings already available"
fi

# --- Step 4: Clone / pull the repo ------------------------------------------

if [ -d "$INSTALL_DIR/.git" ]; then
    banner "Updating existing install at $INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only
else
    banner "Cloning repo to $INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# --- Step 5: Run setup.sh (upstream download, venv, deps) -------------------

banner "Downloading TomoTexture and setting up"
cd "$INSTALL_DIR"
./setup.sh

# --- Step 6: Desktop shortcut -----------------------------------------------

ln -sfn "$INSTALL_DIR/TomoTexture.command" "$HOME/Desktop/TomoTexture.command"
ok "Added TomoTexture.command to your Desktop"

# --- Done -------------------------------------------------------------------

banner "All done!"
cat <<'OUTRO'
Double-click TomoTexture.command on your Desktop to launch the app.

On first launch, the app will ask for:
  - SAVE LOCATION   -> your Ryujinx save folder (see README)
  - BACKUP LOCATION -> any folder you want backups stored in

You can close this window now.
OUTRO
