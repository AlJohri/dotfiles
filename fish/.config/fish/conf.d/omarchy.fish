# Add omarchy bin to PATH. Locally this is inherited from uwsm
# (~/.config/uwsm/env), but over SSH there is no uwsm so the
# omarchy-fish package (which doesn't add it) leaves it missing.
# https://github.com/omacom-io/omarchy-fish/tree/master
fish_add_path ~/.local/share/omarchy/bin
