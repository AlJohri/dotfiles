.PHONY: omarchy ubuntu macos portable stow-core stow-omarchy stow-ubuntu stow-macos stow-portable

# Package groups
CORE = nvim tmux git fish starship mise delta claude-history zsh
DESKTOP = bash scripts alacritty ghostty xdg zed applications code-server
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
# claude is part of core but uses --no-folding so ~/.claude/skills/ stays a
# real directory, leaving room for skills managed outside this repo.
stow-core:
	stow --adopt -t ~ $(CORE)
	stow --adopt --no-folding -t ~ claude

stow-omarchy: stow-core
	stow --adopt -t ~ $(DESKTOP) $(WAYLAND)

stow-ubuntu: stow-core
	stow --adopt -t ~ $(DESKTOP)

stow-macos: stow-core
	stow --adopt -t ~ $(DESKTOP) $(MACOS)

stow-portable: stow-core
