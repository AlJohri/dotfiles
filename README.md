[![Build Status](https://travis-ci.org/AlJohri/dotfiles.svg?branch=master)](https://travis-ci.org/AlJohri/dotfiles)

# Dotfiles

Use https://macos-strap.herokuapp.com/ to install.

## Brewfile

Use this command to update the Brewfile: `brew bundle dump --file=/dev/stdout`

Note that the Brewfile needs to have some dependencies at the top such as `adoptopenjdk8` and `osxfuse`. Also we need to add `unless` clauses for CI and pre-installed GUI apps in the Applicaitons folder.
