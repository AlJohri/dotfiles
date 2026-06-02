# Add omarchy bin to PATH. Locally this is inherited from uwsm
# (~/.config/uwsm/env), but over SSH there is no uwsm so the
# omarchy-fish package (which doesn't add it) leaves it missing.
# https://github.com/omacom-io/omarchy-fish/tree/master
#
# --append so ~/bin (added by 00-path.fish) wins, letting wrappers in
# scripts/bin/ (e.g. omarchy-update) shadow the upstream commands.
fish_add_path --append ~/.local/share/omarchy/bin
