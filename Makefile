.PHONY: omarchy ubuntu macos portable stow-omarchy stow-ubuntu stow-macos stow-portable

# Package groups
CORE = nvim tmux git fish starship mise delta claude claude-history
DESKTOP = bash zsh scripts alacritty ghostty xdg zed applications code-server
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

# Stow only (no deps)
stow-omarchy:
	stow --adopt -t ~ $(CORE) $(DESKTOP) $(WAYLAND)

stow-ubuntu:
	stow --adopt -t ~ $(CORE) $(DESKTOP)

stow-macos:
	stow --adopt -t ~ $(CORE) $(DESKTOP) $(MACOS)

stow-portable:
	stow --adopt -t ~ $(CORE)
