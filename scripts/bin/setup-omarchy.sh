#!/usr/bin/env bash
set -euo pipefail

# Setup script for Omarchy Linux (Arch-based)

echo "==> Syncing package databases..."
sudo pacman -Sy

# github-cli is also installed via mise, but we need it here early so
# `gh auth token` is available to provide GITHUB_TOKEN for mise install,
# avoiding GitHub API rate limits.
echo "==> Installing extra packages (not in omarchy-base)..."
sudo pacman -S --noconfirm --needed \
    stow \
    make \
    fish \
    omarchy-fish \
    omarchy-zsh \
    bolt \
    caligula \
    nvtop \
    sshpass \
    tcpdump \
    tigervnc \
    tmux \
    wayvnc \
    github-cli \
    wget \
    xclip

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

if ! gh auth token &>/dev/null; then
    echo "==> Logging into GitHub (mise installs binaries from GitHub in bulk and will get 403 rate-limited without a token)..."
    gh auth login
fi

echo "==> Installing mise tools..."
mise trust "$DOTFILES_DIR/mise/.config/mise"
GITHUB_TOKEN="$(gh auth token)" mise install -C "$DOTFILES_DIR/mise/.config/mise"

# aws-session-manager-plugin cannot be installed through mise:
# - aqua backend only lists macOS: https://github.com/aquaproj/aqua-registry/blob/main/pkgs/aws/session-manager-plugin/registry.yaml
# - non-standard Go project structure prevents use of the go backend: https://github.com/aws/session-manager-plugin
echo "==> Installing AUR packages..."
yay -S --noconfirm --needed \
    hyprmon-bin \
    slack-desktop \
    volumeboost \
    aws-session-manager-plugin

fprint_output=$(fprintd-list "$USER" 2>&1 || true)
if ! command -v fprintd-list &>/dev/null; then
    echo "==> fprintd not found, skipping fingerprint setup."
elif echo "$fprint_output" | grep -q "No devices available"; then
    echo "==> No fingerprint reader found, skipping fingerprint setup."
elif echo "$fprint_output" | grep -q "#[0-9]"; then
    echo "==> Fingerprint already enrolled, skipping setup."
else
    echo "==> Setting up fingerprint authentication..."
    omarchy-setup-fingerprint
fi

if ! command -v claude &> /dev/null; then
    echo "==> Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

echo "==> Installing and setting up Google Chrome..."
"$DOTFILES_DIR/scripts/bin/setup-chrome.sh"

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

echo "==> Done! Restart your shell or run: exec fish"
