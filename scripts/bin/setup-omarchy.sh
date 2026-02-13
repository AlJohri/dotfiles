#!/usr/bin/env bash
set -euo pipefail

# Setup script for Omarchy Linux (Arch-based)

echo "==> Syncing package databases..."
sudo pacman -Sy

# github-cli is also installed via mise, but we need it here early so
# `gh auth token` is available to provide GITHUB_TOKEN for mise install,
# avoiding GitHub API rate limits.
echo "==> Installing extra packages (not in omarchy-base)..."
# rendering images: kitten icat image.png, chafa image.png
sudo pacman -S --noconfirm --needed \
    stow \
    make \
    most \
    moreutils \
    strace \
    fish \
    omarchy-fish \
    omarchy-zsh \
    bolt \
    caligula \
    nvtop \
    fprintd \
    sshpass \
    tcpdump \
    tigervnc \
    tmux \
    wayvnc \
    github-cli \
    wget \
    xclip \
    git-delta \
    sublime-text-4 \
    tree \
    visual-studio-code-bin \
    zed \
    pandoc-cli \
    kitty \
    chafa

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

if ! gh auth token &>/dev/null; then
    echo "==> Logging into GitHub (mise installs binaries from GitHub in bulk and will get 403 rate-limited without a token)..."
    gh auth login
fi

if [ ! -f "$HOME/.local/bin/mise" ]; then
    echo "==> Installing mise via curl (for self-update support)..."
    curl https://mise.run | sh
fi

echo "==> Installing mise tools..."
mise trust "$DOTFILES_DIR/mise/.config/mise/config.toml"
GITHUB_TOKEN="$(gh auth token)" mise install -C "$DOTFILES_DIR/mise/.config/mise"
eval "$(mise env -s bash --cd "$DOTFILES_DIR/mise/.config/mise")"

# libappindicator-gtk3 is required for Dropbox's tray icon
# aws-session-manager-plugin cannot be installed through mise:
# - aqua backend only lists macOS: https://github.com/aquaproj/aqua-registry/blob/main/pkgs/aws/session-manager-plugin/registry.yaml
# - non-standard Go project structure prevents use of the go backend: https://github.com/aws/session-manager-plugin
echo "==> Installing AUR packages..."
yay -S --noconfirm --needed \
    hyprmon-bin \
    slack-desktop \
    volumeboost \
    aws-session-manager-plugin \
    dropbox \
    dropbox-cli \
    nautilus-dropbox \
    libappindicator-gtk3

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

if ! command -v claude &> /dev/null && [[ ! -x "$HOME/.claude/local/bin/claude" ]]; then
    echo "==> Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

# code-server is installed via mise (see mise config).
if [ ! -f "$HOME/.config/code-server/.env" ]; then
    echo "==> Generating code-server password..."
    mkdir -p "$HOME/.config/code-server"
    password=$(openssl rand -hex 16)
    echo "PASSWORD=$password" > "$HOME/.config/code-server/.env"
    chmod 600 "$HOME/.config/code-server/.env"
    echo "    Password saved to ~/.config/code-server/.env"
fi

if ! systemctl --user is-enabled code-server &>/dev/null; then
    echo "==> Enabling code-server service..."
    loginctl enable-linger "$USER"
    systemctl --user daemon-reload
    systemctl --user enable --now code-server
fi

if ! command -v tailscale &>/dev/null; then
    echo "==> Installing Tailscale (+ tsui, webapp, TUI entry)..."
    omarchy-install-tailscale
fi

echo "==> Installing and setting up Google Chrome..."
"$DOTFILES_DIR/scripts/bin/setup-chrome.sh"

echo "==> Configuring Slack to auto-hide menu bar..."
slack_config="$HOME/.config/Slack/storage/root-state.json"
if [ -f "$slack_config" ] && jq -e '.settings.autoHideMenuBar == false' "$slack_config" &>/dev/null; then
    jq '.settings.autoHideMenuBar = true | .settings.userChoices.autoHideMenuBar = true' "$slack_config" | sponge "$slack_config"
    echo "    Set autoHideMenuBar to true."
else
    echo "    Skipped (file missing or already set)."
fi

echo "==> Allowing direnv..."
mise exec direnv -- direnv allow "$DOTFILES_DIR"

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
