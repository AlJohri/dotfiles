#!/usr/bin/env bash
set -euo pipefail

# Setup script for Omarchy Linux (Arch-based)

echo "==> Syncing package databases..."
sudo pacman -Sy

echo "==> Installing extra packages (not in omarchy-base)..."
sudo pacman -S --noconfirm --needed \
    stow \
    make \
    fish \
    omarchy-fish \
    omarchy-zsh

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

echo "==> Stowing dotfiles..."
make stow-omarchy

# --adopt pulls existing files into the repo, which on a fresh install means
# omarchy's defaults overwrite our tracked files. Show what changed and let
# the user decide whether to restore their versions.
if ! git diff --quiet; then
    echo ""
    echo "==> stow --adopt imported the following changes from system defaults:"
    echo "    (These are typically omarchy package defaults that differ from your dotfiles.)"
    echo ""
    git --no-pager diff --stat
    echo ""
    git --no-pager diff
    echo ""
    read -rp "==> Restore your dotfiles versions? (Y/n) " answer
    if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
        git checkout .
        echo "==> Restored dotfiles to your tracked versions."
    else
        echo "==> Keeping adopted changes."
    fi
fi

echo "==> Installing mise tools..."
mise install

if ! command -v fprintd-list &>/dev/null || ! fprintd-list "$USER" 2>&1 | grep -q "#[0-9]"; then
    echo "==> Setting up fingerprint authentication..."
    omarchy-setup-fingerprint
else
    echo "==> Fingerprint already enrolled, skipping setup."
fi

echo "==> Installing and setting up Google Chrome..."
"$DOTFILES_DIR/scripts/bin/setup-chrome.sh"

echo "==> Done! Restart your shell or run: exec fish"
