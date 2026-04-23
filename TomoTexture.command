#!/bin/bash
# TomoTexture launcher for macOS
# Double-click this file (or run from Terminal) to launch TomoTexture.
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -x "$DIR/.venv/bin/python" ]; then
    echo "TomoTexture: missing $DIR/.venv/bin/python — did setup run?" >&2
    exit 1
fi
if [ ! -f "$DIR/app_runtime/__main__.pyc" ]; then
    echo "TomoTexture: missing $DIR/app_runtime/__main__.pyc — bundle is incomplete." >&2
    exit 1
fi

exec "$DIR/.venv/bin/python" "$DIR/launcher.py" "$@"
