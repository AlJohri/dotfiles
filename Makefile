.PHONY: omarchy ubuntu macos portable stow-omarchy stow-ubuntu stow-portable

# Package groups
CORE = nvim tmux git fish starship mise
DESKTOP = bash zsh scripts alacritty ghostty xdg zed
WAYLAND = hypr waybar hyprmon uwsm wayvnc

# Full setup (deps + stow)
omarchy:
	./scripts/bin/setup-omarchy.sh

ubuntu:
	./scripts/bin/setup-ubuntu.sh

macos:
	./scripts/bin/setup-macos.sh

portable:
	./scripts/bin/setup-portable.sh

# Stow only (no deps)
stow-omarchy:
	stow --adopt $(CORE) $(DESKTOP) $(WAYLAND)
	stow --adopt --no-folding -t ~/.local delta applications

stow-ubuntu:
	stow --adopt $(CORE) $(DESKTOP)
	stow --adopt --no-folding -t ~/.local delta applications

stow-portable:
	stow --adopt $(CORE)
	stow --adopt --no-folding -t ~/.local delta
