#!/bin/bash
# TomoTexture launcher for macOS
# Double-click this file (or run from Terminal) to launch TomoTexture.
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -x "$DIR/.venv/bin/python" ] || [ ! -f "$DIR/app_runtime/__main__.pyc" ]; then
    echo "TomoTexture: install is incomplete — setup didn't finish successfully." >&2
    echo "Re-run setup with:" >&2
    echo "    cd \"$DIR\" && ./setup.sh" >&2
    echo "If that still fails, open an issue at" >&2
    echo "    https://github.com/zachmtz08/tomotexture-port/issues" >&2
    echo "and paste the full output of setup.sh." >&2
    exit 1
fi

exec "$DIR/.venv/bin/python" "$DIR/launcher.py" "$@"
