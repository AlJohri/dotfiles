#!/usr/bin/env bash
set -euo pipefail

# Setup script for Omarchy Linux (Arch-based)

# Sync package databases only if they don't exist yet (fresh system).
# On an already-synced system, skip `pacman -Sy` to avoid the partial-upgrade
# trap: refreshing DBs without `-u` can pull new deps (e.g. libcbor soname bumps)
# that conflict with installed packages still pinned to the old soname.
if ! compgen -G "/var/lib/pacman/sync/*.db" > /dev/null; then
    echo "==> Syncing package databases (first run)..."
    sudo pacman -Sy
fi

# github-cli is also installed via mise, but we need it here early so
# `gh auth token` is available to provide GITHUB_TOKEN for mise install,
# avoiding GitHub API rate limits.
echo "==> Installing extra packages (not in omarchy-base)..."
# bc: arbitrary-precision calculator language, also used by scripts that need shell arithmetic with decimals
# rendering images: kitten icat image.png, chafa image.png
sudo pacman -S --noconfirm --needed \
    bc \
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
    pandoc-cli \
    kitty \
    chafa \
    wine \
    fwupd \
    dmidecode

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

if ! gh auth token &>/dev/null; then
    echo "==> Logging into GitHub (mise installs binaries from GitHub in bulk and will get 403 rate-limited without a token)..."
    gh auth login
fi

if ! gh extension list | grep -q '^gh image'; then
    echo "==> Installing gh-image extension..."
    gh extension install drogers0/gh-image
fi

# Generate an SSH key for signing git commits and register it with GitHub.
# The stowed git config enables ssh commit signing (commit.gpgsign + gpg.format=ssh +
# user.signingkey=~/.ssh/id_ed25519.pub), so commits fail on a fresh box without this.
# Idempotent: generate only if missing; upload only if not already a GitHub signing key.
SSH_SIGNING_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_SIGNING_KEY" ]; then
    echo "==> Generating SSH signing key..."
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$SSH_SIGNING_KEY" -N ""
fi

# Listing/adding signing keys needs the admin:ssh_signing_key scope, which
# `gh auth login` doesn't grant by default.
if ! gh api user/ssh_signing_keys --jq '.[].key' 2>/dev/null | grep -qF "$(awk '{print $2}' "$SSH_SIGNING_KEY.pub")"; then
    echo "==> Registering SSH signing key with GitHub..."
    if gh auth refresh -h github.com -s admin:ssh_signing_key; then
        gh ssh-key add "$SSH_SIGNING_KEY.pub" --type signing --title "$(hostname) (omarchy)" \
            || echo "    Add ~/.ssh/id_ed25519.pub manually: https://github.com/settings/ssh/new (Key type: Signing)"
    else
        echo "    Skipped (auth refresh declined). Add ~/.ssh/id_ed25519.pub manually later."
    fi
fi

# omarchy-fish/omarchy-zsh pull in an older /usr/bin/mise as a dependency, which
# wins on PATH. Use the curl-installed mise in ~/.local/bin explicitly so install
# runs on the latest (self-updating) version, not the pacman one.
MISE="$HOME/.local/bin/mise"
if [ ! -x "$MISE" ]; then
    echo "==> Installing mise via curl (for self-update support)..."
    curl https://mise.run | sh
fi

echo "==> Installing mise tools..."
# MISE_EXPERIMENTAL=1: `experimental` is a global-only setting, so the experimental
# backends in our config (conda:, zerobrew:) are NOT enabled by the project config
# passed via -C at install time. The stowed global ~/.config/mise/config.toml sets
# experimental=true for runtime; pass it via env here so the install itself works.
"$MISE" trust "$DOTFILES_DIR/mise/.config/mise/config.toml"
GITHUB_TOKEN="$(gh auth token)" MISE_EXPERIMENTAL=1 "$MISE" install -C "$DOTFILES_DIR/mise/.config/mise"
eval "$("$MISE" env -s bash --cd "$DOTFILES_DIR/mise/.config/mise")"

# libappindicator-gtk3 is required for Dropbox's tray icon
# aws-session-manager-plugin cannot be installed through mise:
# - aqua backend only lists macOS: https://github.com/aquaproj/aqua-registry/blob/main/pkgs/aws/session-manager-plugin/registry.yaml
# - non-standard Go project structure prevents use of the go backend: https://github.com/aws/session-manager-plugin
echo "==> Installing AUR packages..."
# PATH override: mise (activated above) injects toolchain shims that can hijack
# `ld` during AUR builds, causing source-built packages (snapd, lib32-gstreamer,
# etc.) to fail linking against the system glibc/glib. Scope yay's PATH to the
# system toolchain for this one invocation; mise stays active for later steps.
#
# --assume-installed lib32-jack=lib32-pipewire-jack: lib32-gstreamer (pulled in
# transitively by proton-ge-custom / Steam / Wine) depends on the virtual
# `lib32-jack`, which has two providers: lib32-jack2 and lib32-pipewire-jack.
# With --noconfirm, yay silently picks the default (lib32-jack2), which would
# uninstall lib32-pipewire-jack and break PipeWire's JACK routing. Pin the
# PipeWire shim explicitly.
PATH=/usr/bin:/usr/local/bin yay -S --noconfirm --needed \
    --assume-installed lib32-jack=lib32-pipewire-jack \
    hyprmon-bin \
    slack-desktop \
    volumeboost \
    aws-session-manager-plugin \
    dropbox \
    dropbox-cli \
    nautilus-dropbox \
    libappindicator-gtk3 \
    proton-ge-custom

# Replaces the old AMD-only `lib32-vulkan-radeon` step: `omarchy install gaming
# steam` installs steam and auto-detects the lib32 Vulkan/NVIDIA drivers for any
# attached GPU (Intel/AMD/NVIDIA). It also auto-launches the Steam GUI at the end,
# so only run it when steam isn't installed yet (keeps re-runs from popping the GUI).
if ! pacman -Q steam &>/dev/null; then
    echo "==> Installing Steam + GPU lib32 drivers..."
    omarchy install gaming steam
fi

# Install Zed via omarchy (not the bare `zed` package) so it pulls in `omazed` and
# runs `omazed setup`, wiring up live theming. Guard on zed+omazed being present so
# re-runs don't (a) pop the Zed GUI and (b) re-run `omazed setup`, which clobbers
# ~/.config/zed/settings.json when it lacks a "theme" key.
if ! pacman -Q zed omazed &>/dev/null; then
    echo "==> Installing Zed (with omarchy live theming)..."
    omarchy install zed
fi

if [ -n "${SSH_CONNECTION:-}" ]; then
    echo "==> SSH session detected, skipping fingerprint setup (requires physical access)."
else
    fprint_output=$(fprintd-list "$USER" 2>&1 || true)
    if ! command -v fprintd-list &>/dev/null; then
        echo "==> fprintd not found, skipping fingerprint setup."
    elif echo "$fprint_output" | grep -q "No devices available"; then
        echo "==> No fingerprint reader found, skipping fingerprint setup."
    elif echo "$fprint_output" | grep -q "#[0-9]"; then
        echo "==> Fingerprint already enrolled, skipping setup."
    else
        echo "==> Setting up fingerprint authentication..."
        omarchy-setup-security-fingerprint
    fi
fi

if ! command -v claude &> /dev/null && [[ ! -x "$HOME/.claude/local/bin/claude" ]]; then
    echo "==> Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

echo "==> Installing Claude Code MCP servers..."
"$DOTFILES_DIR/scripts/bin/setup-claude-code-mcp-servers.sh"

echo "==> Configuring Claude Code settings..."
"$DOTFILES_DIR/scripts/bin/setup-claude-code-settings.sh"

# code-server is installed via mise (see mise config).
if [ ! -f "$HOME/.config/code-server/.env" ]; then
    echo "==> Generating code-server password..."
    mkdir -p "$HOME/.config/code-server"
    password=$(openssl rand -hex 16)
    echo "PASSWORD=$password" > "$HOME/.config/code-server/.env"
    chmod 600 "$HOME/.config/code-server/.env"
    echo "    Password saved to ~/.config/code-server/.env"
fi

if ! command -v tailscale &>/dev/null; then
    echo "==> Installing Tailscale (+ tsui, webapp, TUI entry)..."
    omarchy-install-tailscale
fi

echo "==> Installing Google Chrome..."
# `omarchy install browser chrome` installs google-chrome (AUR), creates the
# /etc/opt/chrome/policies/managed policy dir, drops in ~/.config/chrome-flags.conf,
# and wires up theme integration. The default-browser handoff happens after stow
# (below), once ~/.config/mimeapps.list is our symlink.
omarchy install browser chrome

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

echo "==> Stowing dotfiles (review any incoming changes per file)..."
"$DOTFILES_DIR/scripts/bin/stow-review.sh"

# Now that ~/.config/mimeapps.list is our symlink (which already maps http/https
# to google-chrome.desktop), register Chrome as the xdg default. xdg-mime writes
# through the symlink in place, so this is idempotent and leaves the repo clean.
echo "==> Setting Chrome as the default browser..."
omarchy default browser chrome

# Enable code-server now that its unit (code-server/.config/systemd/user/) has been
# stowed above -- on a fresh machine the unit doesn't exist until stow runs.
if ! systemctl --user is-enabled code-server &>/dev/null; then
    echo "==> Enabling code-server service..."
    loginctl enable-linger "$USER"
    systemctl --user daemon-reload
    systemctl --user enable --now code-server
fi

echo "==> Done! Restart your shell or run: exec fish"
