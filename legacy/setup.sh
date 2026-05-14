#!/bin/bash
# TomoTexture macOS setup.
# Downloads the upstream Windows release from Alfonso Mallozzi's repo,
# extracts the PyInstaller bundle, and copies the required .pyc modules
# into app_runtime/. Also creates a Python 3.14 .venv with the runtime deps.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

UPSTREAM_URL="https://github.com/AlfonsoMallozzi/TomoTexture/releases/download/release/TomoTexture1.1.exe"
EXE="TomoTexture1.1.exe"
EXTRACT_DIR="TomoTexture1.1.exe_extracted"
RUNTIME="app_runtime"

if ! command -v python3.14 >/dev/null 2>&1; then
    echo "Error: Python 3.14 is required (the bundled .pyc magic matches 3.14 only)." >&2
    echo "Install via: brew install python@3.14" >&2
    exit 1
fi

# A pre-existing .venv missing its python binary is broken (e.g. previous
# setup run aborted mid-creation). Wipe it so we recreate from scratch.
if [ -d ".venv" ] && [ ! -x ".venv/bin/python" ]; then
    echo "Removing incomplete .venv..."
    rm -rf .venv
fi

if [ ! -d ".venv" ]; then
    echo "Creating .venv with Python 3.14..."
    # Some Homebrew python@3.14 builds ship a broken ensurepip; fall back to
    # creating the venv without pip and bootstrapping via get-pip.py.
    if ! python3.14 -m venv .venv 2>/tmp/tomotexture-venv.err; then
        echo "Standard venv creation failed; retrying without pip..."
        rm -rf .venv
        python3.14 -m venv --without-pip .venv
    fi
fi

if [ ! -x ".venv/bin/pip" ]; then
    echo "Bootstrapping pip via get-pip.py..."
    curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/tomotexture-get-pip.py
    .venv/bin/python /tmp/tomotexture-get-pip.py --quiet
    rm -f /tmp/tomotexture-get-pip.py
fi

echo "Installing dependencies into .venv..."
.venv/bin/pip install --quiet --upgrade pip
.venv/bin/pip install --quiet -r requirements.txt pyinstxtractor-ng

if [ ! -f "$EXE" ]; then
    echo "Downloading $EXE (~34 MB) from upstream..."
    curl -L --fail --output "$EXE" "$UPSTREAM_URL"
fi

if [ ! -d "$EXTRACT_DIR" ]; then
    echo "Extracting $EXE..."
    .venv/bin/pyinstxtractor-ng "$EXE"
fi

mkdir -p "$RUNTIME"
cp "$EXTRACT_DIR/app.pyc" "$RUNTIME/__main__.pyc"
cp "$EXTRACT_DIR/PYZ.pyz_extracted/swizzle.pyc" "$RUNTIME/swizzle.pyc"
cp "$EXTRACT_DIR/PYZ.pyz_extracted/tex_format.pyc" "$RUNTIME/tex_format.pyc"

echo
echo "Setup complete. Launch with: ./TomoTexture.command"
