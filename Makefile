.PHONY: all

all:
	stow --adopt --restow scripts bash zsh fish hypr waybar tmux hyprmon starship git nvim alacritty
	stow --adopt --restow --no-folding -t ~/.local delta
