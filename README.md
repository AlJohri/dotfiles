[![Build Status](https://travis-ci.org/AlJohri/dotfiles.svg?branch=master)](https://travis-ci.org/AlJohri/dotfiles)

# Dotfiles

Use https://macos-strap.herokuapp.com/ to install.

## Brewfile

Use this command to update the Brewfile: `brew bundle dump --global --force`. Remember to add these lines:

```
cask "dropbox" unless File.directory?("/Applications/Dropbox.app")
cask "google-chrome-beta" unless File.directory?("/Applications/Google Chrome.app")
cask "slack" unless File.directory?("/Applications/Slack.app")
cask "vlc" unless File.directory?("/Applications/VLC.app")
```
