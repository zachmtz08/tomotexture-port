#!/bin/bash
# TomoTexture macOS one-liner installer.
# Usage (from a macOS Terminal):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/zachmtz08/tomotexture-port/main/install.sh)"
set -euo pipefail

INSTALL_DIR="$HOME/tomotexture-port"
REPO_URL="https://github.com/zachmtz08/tomotexture-port.git"

say() { printf '\n\033[1;34m==\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$1" >&2; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

say "TomoTexture macOS installer"

if ! command -v git >/dev/null 2>&1; then
    warn "git not found. macOS will now prompt you to install the Xcode Command Line Tools."
    warn "Accept the prompt, wait for the install to finish, then re-run this installer."
    xcode-select --install >/dev/null 2>&1 || true
    exit 1
fi

if ! command -v python3.14 >/dev/null 2>&1; then
    warn "Python 3.14 is required (bundled .pyc magic matches 3.14 only)."
    warn "Install it with Homebrew, then re-run this installer:"
    warn "    brew install python@3.14"
    die "missing Python 3.14"
fi

if [ -d "$INSTALL_DIR/.git" ]; then
    say "Updating existing install at $INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only
else
    say "Cloning to $INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
say "Running setup (downloads upstream release, sets up venv)"
./setup.sh

say "Creating Desktop shortcut"
ln -sfn "$INSTALL_DIR/TomoTexture.command" "$HOME/Desktop/TomoTexture.command"

printf '\n\033[1;32mDone!\033[0m Double-click \033[1mTomoTexture.command\033[0m on your Desktop to launch.\n\n'
