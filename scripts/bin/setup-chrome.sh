#!/usr/bin/env bash
set -euo pipefail

# Setup Google Chrome policy directory for omarchy theme integration
# This mirrors what omarchy does for Chromium/Brave in install/config/theme.sh

CHROME_POLICY_DIR="/etc/opt/chrome/policies/managed"

if [[ -d "$CHROME_POLICY_DIR" ]]; then
    echo "==> Chrome policy directory already exists: $CHROME_POLICY_DIR"
else
    echo "==> Creating Chrome policy directory..."
    sudo mkdir -p "$CHROME_POLICY_DIR"
    sudo chmod a+rw "$CHROME_POLICY_DIR"
    echo "==> Created $CHROME_POLICY_DIR"
fi
