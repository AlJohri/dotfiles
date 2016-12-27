#!/bin/sh
# Colourful manpages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Set to avoid `env` output from changing console colour
export LESS_TERMEND=$'\E[0m'

# Print field by number
field() {
  ruby -ane "puts \$F[$1]"
}

# Setup paths
remove_from_path() {
  [ -d $1 ] || return
  # Doesn't work for first item in the PATH but I don't care.
  export PATH=$(echo $PATH | sed -e "s|:$1||") 2>/dev/null
}

add_to_path_start() {
  [ -d $1 ] || return
  remove_from_path "$1"
  export PATH="$1:$PATH"
}

add_to_path_end() {
  [ -d "$1" ] || return
  remove_from_path "$1"
  export PATH="$PATH:$1"
}

force_add_to_path_start() {
  remove_from_path "$1"
  export PATH="$1:$PATH"
}

quiet_which() {
  which $1 &>/dev/null
}

add_to_path_start "/usr/local/bin"
add_to_path_start "/usr/local/sbin"

quiet_which pyenv && eval "$(pyenv init -)"
quiet_which rbenv && eval "$(rbenv init -)"
quiet_which nodenv && eval "$(nodenv init -)"
pyenv virtualenvwrapper

# Aliases
alias git=hub
alias cp='cp -irv'
alias rm='rm -iv'
alias mv='mv -iv'
alias gst='git status'

# Platform-specific stuff
quiet_which brew && export HOMEBREW_CASK_OPTS="--appdir=/Applications"

if [ $OSX ]
then
  export GREP_OPTIONS="--color=auto"
  export CLICOLOR=1
  export LSCOLORS=GxFxCxDxBxegedabagaced
  export VAGRANT_DEFAULT_PROVIDER="vmware_fusion"
  if quiet_which diff-highlight
  then
    export GIT_PAGER='diff-highlight | less -+$LESS -RX'
  else
    export GIT_PAGER='less -+$LESS -RX'
  fi

  add_to_path_end /Applications/Xcode.app/Contents/Developer/usr/bin
  add_to_path_end /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
  add_to_path_end "$BREW_PREFIX/opt/git/share/git-core/contrib/diff-highlight"

  alias ls="ls -F"
  alias ql="qlmanage -p 1>/dev/null"
  alias locate="mdfind -name"
  alias cpwd="pwd | tr -d '\n' | pbcopy"
  alias finder-hide="setfile -a V"

  # Old default Curl is broken for Git on Leopard.
  [ "$OSTYPE" = "darwin9.0" ] && export GIT_SSL_NO_VERIFY=1
fi

# Run dircolors if it exists
quiet_which dircolors && eval $(dircolors -b)

# More colours with grc
[ -f "$BREW_PREFIX/etc/grc.bashrc" ] && source "$BREW_PREFIX/etc/grc.bashrc"

# Save directory changes
cd() {
  builtin cd "$@" || return
  [ $TERMINALAPP ] && which set_terminal_app_pwd &>/dev/null \
    && set_terminal_app_pwd
  pwd > "$HOME/.lastpwd"
  ls
}

# Look in ./bin but do it last to avoid weird `which` results.
force_add_to_path_start "bin"
