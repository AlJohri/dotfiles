#!/usr/bin/env bash
set -euo pipefail

# Setup script for Omarchy Linux (Arch-based)

# Ensure omarchy's own bin dir is on PATH. Interactive fish adds it via
# conf.d/omarchy.fish, but this script may run from a non-interactive or SSH bash shell
# where it's absent, and later steps invoke `omarchy`, `omarchy-install-terminal`,
# `omarchy-setup-security-fingerprint`, etc.
OMARCHY_BIN="$HOME/.local/share/omarchy/bin"
if [[ ":$PATH:" != *":$OMARCHY_BIN:"* ]]; then
    export PATH="$OMARCHY_BIN:$PATH"
fi

# Sync package databases only if they don't exist yet (fresh system).
# On an already-synced system, skip `pacman -Sy` to avoid the partial-upgrade
# trap: refreshing DBs without `-u` can pull new deps (e.g. libcbor soname bumps)
# that conflict with installed packages still pinned to the old soname.
if ! compgen -G "/var/lib/pacman/sync/*.db" > /dev/null; then
    echo "==> Syncing package databases (first run)..."
    sudo pacman -Sy
fi

# github-cli must be installed before mise: `gh auth token` provides GITHUB_TOKEN for
# `mise install` (avoids GitHub API rate limits), and it's needed before the mise binary
# even exists (installed via curl below). The rest of the system packages are declared in
# [bootstrap.packages] and installed by `mise bootstrap packages apply --manager pacman`
# further down — after the mise binary is available.
echo "==> Installing github-cli (needed early for gh auth token)..."
sudo pacman -S --noconfirm --needed github-cli

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

if ! gh auth token &>/dev/null; then
    echo "==> Logging into GitHub (mise installs binaries from GitHub in bulk and will get 403 rate-limited without a token)..."
    # Request admin:ssh_signing_key upfront so the signing-key registration step
    # below can list/add keys without a separate device-code prompt later.
    # BROWSER=echo: print the device-flow URL instead of launching Chrome, which
    # would otherwise spew its startup stderr (TF Lite, GCM, mojo) into this terminal.
    BROWSER=echo gh auth login -s admin:ssh_signing_key
fi

# Ensure the signing-key scope is present even if `gh auth login` was run
# previously without -s (e.g. on machines set up before this change).
if ! gh auth status 2>&1 | grep -q 'admin:ssh_signing_key'; then
    # The refresh is a device-code flow (interactive). Guard on a TTY so headless
    # runs skip it instead of hanging forever waiting for a browser confirmation.
    if [ -t 0 ]; then
        echo "==> Adding admin:ssh_signing_key scope to gh token..."
        BROWSER=echo gh auth refresh -h github.com -s admin:ssh_signing_key \
            || echo "    Skipped. Add ~/.ssh/id_ed25519.pub manually later: https://github.com/settings/ssh/new"
    else
        echo "==> gh token lacks admin:ssh_signing_key scope; no TTY, skipping interactive refresh."
        echo "    Run: gh auth refresh -h github.com -s admin:ssh_signing_key"
    fi
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

# Scope was requested at `gh auth login` time above, so listing here works
# without a per-run device-code prompt.
if ! gh api user/ssh_signing_keys --jq '.[].key' 2>/dev/null | grep -qF "$(awk '{print $2}' "$SSH_SIGNING_KEY.pub")"; then
    echo "==> Registering SSH signing key with GitHub..."
    gh ssh-key add "$SSH_SIGNING_KEY.pub" --type signing --title "$(hostname) (omarchy)" \
        || echo "    Add ~/.ssh/id_ed25519.pub manually: https://github.com/settings/ssh/new (Key type: Signing)"
fi

# omarchy-fish/omarchy-zsh pull in an older /usr/bin/mise as a dependency, which
# wins on PATH. Use the curl-installed mise in ~/.local/bin explicitly so install
# runs on the latest (self-updating) version, not the pacman one.
MISE="$HOME/.local/bin/mise"
if [ ! -x "$MISE" ]; then
    echo "==> Installing mise via curl (for self-update support)..."
    curl https://mise.run | sh
fi

# `mise bootstrap packages apply` (below) needs a recent mise -- the [bootstrap.packages]
# parser + subcommand landed ~2026.6.11. A previously curl-installed mise may be older
# (e.g. 2026.6.0 flags `bootstrap` as an unknown field and treats `mise bootstrap` as a
# task name, aborting the run), so self-update before relying on it.
echo "==> Updating mise (needed for bootstrap packages support)..."
"$MISE" self-update -y || echo "    (self-update failed; continuing on $("$MISE" --version 2>/dev/null))"

# Replace the pacman mise (an omarchy-fish/omarchy-zsh dependency) with the empty
# mise-provider package so only the self-managed ~/.local/bin/mise exists. A stale
# /usr/bin/mise is not just a PATH nuisance: mise shims symlink to whichever binary
# ran reshim, and a months-old pacman mise behind the shims caused a
# git-credential-helper fork bomb (pre-jdx/mise#8802). pacman -Rdd first because
# pacman -U --noconfirm auto-DECLINES conflict removals, so the conflicts=('mise')
# in the PKGBUILD can't do the swap unattended.
# Exact-name match (-Qq + grep -x): `pacman -Q mise` resolves virtual provides,
# so after the swap it happily reports mise-provider and would re-enter this
# block, where `pacman -Rdd mise` then fails ("target not found") and aborts
# the run via set -e.
if pacman -Qq | grep -qx mise; then
    echo "==> Replacing pacman mise with mise-provider (real mise is ~/.local/bin/mise)..."
    (cd "$DOTFILES_DIR/pacman/mise-provider" && makepkg -f --noconfirm)
    sudo pacman -Rdd --noconfirm mise
    sudo pacman -U --noconfirm "$DOTFILES_DIR"/pacman/mise-provider/mise-provider-*.pkg.tar.zst
    "$MISE" reshim --force
fi

echo "==> Installing mise tools..."
# MISE_EXPERIMENTAL=1: `experimental` is a global-only setting, so the experimental
# backends in our config (conda:) are NOT enabled by the project config
# passed via -C at install time. The stowed global ~/.config/mise/config.toml sets
# experimental=true for runtime; pass it via env here so the install itself works.
"$MISE" trust "$DOTFILES_DIR/mise/.config/mise/config.toml"
# System packages from [bootstrap.packages], scoped to pacman so the brew: entries
# (macOS) are skipped -- without --manager, apply would set up linuxbrew and build them.
# Runs before `mise install` because some tools build against these (e.g. mip.rs needs
# webkitgtk-6.0's pkg-config files at compile time).
echo "==> Installing system packages via mise bootstrap (pacman)..."
MISE_EXPERIMENTAL=1 "$MISE" bootstrap packages apply --manager pacman -C "$DOTFILES_DIR/mise/.config/mise"
GITHUB_TOKEN="$(gh auth token)" MISE_EXPERIMENTAL=1 "$MISE" install -C "$DOTFILES_DIR/mise/.config/mise"
eval "$("$MISE" env -s bash --cd "$DOTFILES_DIR/mise/.config/mise")"

# libappindicator-gtk3 is required for Dropbox's tray icon
# aws-session-manager-plugin cannot be installed through mise:
# - aqua backend only lists macOS: https://github.com/aquaproj/aqua-registry/blob/main/pkgs/aws/session-manager-plugin/registry.yaml
# - non-standard Go project structure prevents use of the go backend: https://github.com/aws/session-manager-plugin
echo "==> Installing AUR packages..."
# Only install packages that are missing. `yay -S --needed` still REBUILDS an AUR
# package when its AUR version is newer than what's installed -- for proton-ge-custom
# that's a multi-minute source build on every re-run. Filtering to the missing set
# keeps re-runs fast and matches the install-if-absent guards used elsewhere
# (steam/zed/chrome). Pulling AUR updates is `yay -Syu`'s job, not setup's.
aur_pkgs=(
    hyprmon-bin
    slack-desktop
    volumeboost
    aws-session-manager-plugin
    dropbox
    dropbox-cli
    nautilus-dropbox
    libappindicator-gtk3
    proton-ge-custom
    protontricks
)
aur_missing=()
for p in "${aur_pkgs[@]}"; do
    pacman -Q "$p" &>/dev/null || aur_missing+=("$p")
done
if (( ${#aur_missing[@]} )); then
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
        "${aur_missing[@]}"
fi

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

# SSH: enable the daemon, but restrict reachability to the Tailscale interface
# and RFC1918 LAN ranges. Omarchy ships ufw active with default-deny incoming,
# so we add scoped allow rules rather than `ufw allow ssh` (which would open 22
# to the whole world). `ufw allow` is idempotent (it skips a duplicate rule), as
# is `systemctl enable --now`. Note: allowing all of RFC1918 means that on an
# untrusted network (cafe/airport wifi) peers on that subnet can reach port 22 --
# pubkey-only auth is the backstop there; remote access otherwise rides Tailscale.
echo "==> Enabling SSH (Tailscale + LAN only)..."
sudo systemctl enable --now sshd
# Ensure ufw is up before adding rules. Omarchy historically shipped ufw active,
# but on some installs it isn't -- `ufw allow` then fails with "ERROR: problem
# running" because the iptables backend isn't initialized.
sudo systemctl enable --now ufw
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'ssh tailscale'
for net in 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12; do
    sudo ufw allow from "$net" to any port 22 proto tcp comment 'ssh lan'
done

# Size zram to hold real workloads instead of zram-generator's upstream default
# min(ram/2, 4G): on a 27G machine that left a 4G zram permanently full and
# spilled ~13G of cold pages (mostly ghostty scrollback) to the disk swapfile —
# faulting them back from disk made new terminal tabs take ~1s. min(ram, 16G)
# equals ram on <=16G laptops and caps larger machines; the measured workload
# (16G swapped, ~7:1 zstd on terminal text) costs only ~2.3G real RAM compressed.
# The btrfs swapfile is untouched — it stays for hibernation + overflow (pri=0
# vs zram pri=100). page-cluster=0 disables swap readahead, the standard zram
# tuning. Precedent: Fedora 34 "Scale ZRAM to full memory size"; Arch Wiki zram.
# zram resize takes full effect on reboot (device must be recreated).
echo "==> Configuring zram sizing..."
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = min(ram, 16384)
compression-algorithm = zstd
EOF
sudo tee /etc/sysctl.d/99-zram.conf >/dev/null <<'EOF'
vm.page-cluster = 0
EOF
sudo sysctl -q -p /etc/sysctl.d/99-zram.conf

# `omarchy install browser chrome` installs google-chrome (AUR), creates the
# /etc/opt/chrome/policies/managed policy dir, drops in ~/.config/chrome-flags.conf,
# and wires up theme integration. Guarded on `command -v google-chrome-stable` so
# re-runs skip the yay/AUR invocation (sudo prompt + network check) instead of
# re-running it every setup. The default-browser handoff happens after stow
# (below), once ~/.config/mimeapps.list is our symlink.
if ! command -v google-chrome-stable &>/dev/null; then
    echo "==> Installing Google Chrome..."
    omarchy install browser chrome
fi

echo "==> Configuring Slack to auto-hide menu bar..."
slack_config="$HOME/.config/Slack/storage/root-state.json"
if [ -f "$slack_config" ] && jq -e '.settings.autoHideMenuBar == false' "$slack_config" &>/dev/null; then
    jq '.settings.autoHideMenuBar = true | .settings.userChoices.autoHideMenuBar = true' "$slack_config" | sponge "$slack_config"
    echo "    Set autoHideMenuBar to true."
else
    echo "    Skipped (file missing or already set)."
fi

echo "==> Allowing direnv..."
"$MISE" exec direnv -- direnv allow "$DOTFILES_DIR"

# THE stow step (runs stow internally), not just a review -- it creates all the
# ~/.config symlinks. Load-bearing for what follows: the systemd unit enables and the
# Chrome/ghostty default handoffs below rely on the symlinks it lays down. Interactive
# (TTY): --adopt + per-file review, firing only on genuine collisions; needs a clean
# git tree. Non-interactive: safe --restow, no prompts. See scripts/bin/stow-review.sh.
echo "==> Stowing dotfiles (review any incoming changes per file)..."
"$DOTFILES_DIR/scripts/bin/stow-review.sh"

# Sync allowed_signers AFTER stowing. This appends to a TRACKED file, so doing it
# before stow-review would dirty the git tree and trip stow-review's clean-tree guard
# on a fresh install (new machine key). Keeps `git log --show-signature` verifying
# locally once this machine's key is listed; left uncommitted for you to commit.
ALLOWED_SIGNERS="$DOTFILES_DIR/git/.config/git/allowed_signers"
key_field="$(awk '{print $1, $2}' "$SSH_SIGNING_KEY.pub")"
if ! grep -qF "${key_field#* }" "$ALLOWED_SIGNERS" 2>/dev/null; then
    echo "==> Adding this machine's key to git allowed_signers (commit the change to track it)..."
    echo "$(git config -f "$DOTFILES_DIR/git/.config/git/config" --get user.email) $key_field" >>"$ALLOWED_SIGNERS"
fi

# NOTE: we deliberately do NOT run `omarchy default browser chrome` here. Our stowed
# ~/.config/mimeapps.list already sets the browser defaults -- and routes http/https/
# html to google-chrome-link.desktop (a custom link handler). `omarchy default browser
# chrome` overwrites those with plain google-chrome.desktop, reverting the customization
# and dirtying the repo on every run. The stowed mimeapps.list is the source of truth.

# omarchy terminal install + default handoff, split into two steps.
# omarchy-install-terminal installs the ghostty package and its desktop entry
# (guarded on `command -v ghostty` so re-runs don't re-prompt for sudo). Then
# `omarchy default terminal ghostty` -- run every time -- asserts ghostty as the
# xdg-terminal-exec default by writing ~/.config/xdg-terminals.list, which is now
# our symlink (already listing com.mitchellh.ghostty.desktop): the write passes
# through it in place, idempotently and leaving the repo clean. The unconditional
# second step also heals the default after an omarchy update migration rewrites
# the list (omarchy's own default went alacritty -> ghostty in v3.2, then back to
# alacritty in 2026).
if ! command -v ghostty &>/dev/null; then
    echo "==> Installing ghostty..."
    omarchy-install-terminal ghostty
fi
echo "==> Setting ghostty as the default terminal..."
omarchy default terminal ghostty

# Enable ghostty's resident D-Bus service so `ghostty +new-window` (bound to
# SUPER+ENTER in hypr/bindings.conf) dispatches a new window to an already-running
# instance (~20ms) instead of spawning a fresh ghostty and re-initializing GTK
# every time (~450ms surface creation on Hyprland). Unlike code-server/
# claude-remote-control, this unit ships with the ghostty package
# (/usr/lib/systemd/user/app-com.mitchellh.ghostty.service), so it needs no stow
# and no daemon-reload -- just enable it. `--initial-window=false` (in the unit)
# keeps it windowless until a window is requested; it's graphical-session-scoped,
# so no enable-linger. is-enabled reports "disabled" until wired up.
if [ "$(systemctl --user is-enabled app-com.mitchellh.ghostty.service 2>/dev/null)" != "enabled" ]; then
    echo "==> Enabling ghostty D-Bus service (fast new-window)..."
    systemctl --user enable app-com.mitchellh.ghostty.service
    # Start it this session too, but tolerate failure: if a ghostty is already running
    # it owns the com.mitchellh.ghostty D-Bus name, so the resident instance can't claim
    # it and `start` fails with a protocol error. Harmless -- the service is enabled (it
    # starts on next login) and `ghostty +new-window` dispatches to the running instance
    # either way. Without this guard the failure would abort the whole script (set -e).
    systemctl --user start app-com.mitchellh.ghostty.service 2>/dev/null \
        || echo "    (immediate start skipped -- a ghostty is already running; enabled for next login)"
fi

# Enable code-server now that its unit (code-server/.config/systemd/user/) has been
# stowed above -- on a fresh machine the unit doesn't exist until stow runs.
if ! systemctl --user is-enabled code-server &>/dev/null; then
    echo "==> Enabling code-server service..."
    loginctl enable-linger "$USER"
    systemctl --user daemon-reload
    systemctl --user enable --now code-server
fi

# Enable claude-remote-control now that its unit (claude/.config/systemd/user/) has
# been stowed above. `is-enabled` reports "linked" for a stowed-but-not-enabled unit,
# so guard on the literal "enabled" to avoid re-running once it's wired up.
if [ "$(systemctl --user is-enabled claude-remote-control 2>/dev/null)" != "enabled" ]; then
    echo "==> Enabling claude-remote-control service..."
    loginctl enable-linger "$USER"
    systemctl --user daemon-reload
    systemctl --user enable --now claude-remote-control
fi

echo "==> Done! Restart your shell or run: exec fish"
