.PHONY: omarchy ubuntu macos portable stow-core stow-omarchy stow-ubuntu stow-macos stow-portable

# Package groups
CORE = nvim tmux git fish mise delta claude-history zsh
DESKTOP = bash alacritty ghostty xdg applications code-server
MACOS = yabai skhd
WAYLAND = hypr waybar uwsm omarchy wireplumber elephant imv makima wiremix

# Full setup (deps + stow)
omarchy:
	./scripts/bin/setup-omarchy.sh

ubuntu:
	./scripts/bin/setup-ubuntu.sh

macos:
	./scripts/bin/setup-macos.sh

portable:
	./scripts/bin/setup-portable.sh

# Stow only (no deps).
#
# STOW_FLAGS is the conflict strategy. Default --restow is safe and idempotent: it
# re-creates symlinks and FAILS LOUDLY if a real file has replaced one (drift) rather
# than silently absorbing it. The interactive install / post-omarchy-update reconcile
# path (stow-review.sh) overrides this to STOW_FLAGS=--adopt, which pulls pre-existing
# real files INTO the repo so they can be reviewed. Rule of thumb: --adopt on a fresh
# machine or after an omarchy update; --restow (the default) for everyday re-stowing.
STOW_FLAGS ?= --restow
#
# claude, starship, and scripts are core but use --no-folding so ~/.claude/skills/
# and ~/bin stay real directories. starship and scripts both ship a bin/; without
# --no-folding, a core-only (portable) install would fold ~/bin into a symlink to a
# single package's bin, and anything later added to ~/bin would land inside that
# package. claude keeps room for externally-managed skills.
stow-core:
	stow $(STOW_FLAGS) -t ~ $(CORE)
	stow $(STOW_FLAGS) --no-folding -t ~ claude starship scripts

# zed reads a single settings.json and has no per-machine override, so the theme
# lives in a per-OS package (zed-linux = Omazed, zed-macos = native system
# light/dark) while shared config (keymap) stays in the base `zed` package. Both
# are stowed --no-folding (like claude/starship/scripts) so ~/.config/zed stays a
# real dir: that keeps omazed's generated themes/omazed.json a plain local file
# instead of folding it back into a repo symlink.
stow-omarchy: stow-core
	stow $(STOW_FLAGS) -t ~ $(DESKTOP) $(WAYLAND)
	stow $(STOW_FLAGS) --no-folding -t ~ zed zed-linux

stow-ubuntu: stow-core
	stow $(STOW_FLAGS) -t ~ $(DESKTOP)
	stow $(STOW_FLAGS) --no-folding -t ~ zed zed-linux

stow-macos: stow-core
	stow $(STOW_FLAGS) -t ~ $(DESKTOP) $(MACOS)
	stow $(STOW_FLAGS) --no-folding -t ~ zed zed-macos

stow-portable: stow-core
