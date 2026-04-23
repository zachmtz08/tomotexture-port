#!/bin/bash
# Double-click this file to install TomoTexture for macOS.
# It fetches and runs the latest installer from GitHub.
clear
cat <<'BANNER'
========================================
  TomoTexture for macOS — Installer
========================================

Downloading installer from GitHub...
BANNER
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/zachmtz08/tomotexture-port/main/install.sh)"
