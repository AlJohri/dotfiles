# utils

quiet_which() {
  command -v "$1" >/dev/null
}

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

# Run dircolors if it exists
quiet_which dircolors && eval $(dircolors -b)

# More colours with grc
[ -f "$HOMEBREW_PREFIX/etc/grc.bashrc" ] && source "$HOMEBREW_PREFIX/etc/grc.bashrc"

# Aliases

alias ccat='pygmentize -g'
alias git=hub
alias cat=bat
alias cp='cp -irv'
alias rm='rm -iv'
alias mv='mv -iv'
alias gst='git status'
alias ag='rg'
alias curl='noglob curl'
alias nchrome='open -n /Applications/Google\ Chrome.app/'
alias pyclean='find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf'
alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport'

# Functions

function dockercleanup() {
  docker kill $(docker ps -q)
  docker rm $(docker ps -a -q)
  docker rmi $(docker images -q)
}

make_ssh_key() {
  if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -q -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "al.johri@gmail.com"
    eval "$(ssh-agent -s)"
    if [ $OSX ]; then
      ssh-add -K "$HOME/.ssh/id_rsa"
    else
      ssh-add "$HOME/.ssh/id_rsa"
    fi
    pbcopy < "$HOME/.ssh/id_rsa.pub"
    open https://github.com/settings/ssh
  else
    echo "ssh key already exists"
  fi
}

function startgpg() {
  # https://wincent.com/wiki/Using_gpg-agent_on_OS_X
  # https://blog.chendry.org/2015/03/13/starting-gpg-agent-in-osx.html
  export GPG_TTY=$(tty)
  [ -f "$HOME/.gpg-agent-info" ] && source "$HOME/.gpg-agent-info"
  if [ -S "${GPG_AGENT_INFO%%:*}" ]; then
    [ "$debug_dotfiles" = true ] && echo "gpg-agent already started."
    export GPG_AGENT_INFO
  else
    [ "$debug_dotfiles" = true ] && echo "starting new gpg-agent"
    eval $(gpg-agent --allow-preset-passphrase --use-standard-socket --daemon --write-env-file "$HOME/.gpg-agent-info")
  fi

  if [ "$debug_dotfiles" = true ]; then
    USER_EMAIL="$(git config --global --get user.email)"
    KEYGRIP=$(gpg --fingerprint --fingerprint $USER_EMAIL | grep fingerprint | tail -1 | cut -d= -f2 | sed -e 's/ //g')
    echo "GPG_TTY=$GPG_TTY"
    echo "GPG_AGENT_INFO=$GPG_AGENT_INFO"
    echo "KEYGRIP=$KEYGRIP"
  fi
}

# Platform-specific stuff

if [ $OSX ]
then
  export GREP_OPTIONS="--color=auto"
  export CLICOLOR=1
  export LSCOLORS=GxFxCxDxBxegedabagaced

  export LESS="-RFi"

  if quiet_which diff-highlight
  then
    export GIT_PAGER='diff-highlight | less -+$LESS -FRXi'
  else
    export GIT_PAGER='less -+$LESS -FRXi'
  fi

  alias ls="ls -F"
  alias ql="qlmanage -p 1>/dev/null"
  alias locate="mdfind -name"
  alias cpwd="pwd | tr -d '\n' | pbcopy"
  alias finder-hide="setfile -a V"
fi

# Schedule sleep in X minutes, use like: sleep-in 60
function sleepin() {
  local minutes=$1
  local datetime=`date -v+${minutes}M +"%m/%d/%y %H:%M:%S"`
  sudo pmset schedule sleep "$datetime"
}

function sourceenv() {
  export $(grep -v '^#' .env | xargs)
}

background() {
    nohup bash --login -c "$*" &
}

background-log() {
    filename="$1"
    shift
    nohup bash --login -c "$*" &> "$filename" &
}

test -e "${HOME}/iterm2/iterm2_shell_integration.zsh" && source "${HOME}/iterm2/.iterm2_shell_integration.zsh"
[ -f "$HOME/.workrc" ] && source "$HOME/.workrc"

# History file
export HISTFILE=~/.zsh_history

# Don't show duplicate history entires
setopt hist_find_no_dups

# Remove unnecessary blanks from history
setopt hist_reduce_blanks

# Share history between instances
setopt share_history

# Don't hang up background jobs
setopt no_hup

# use emacs bindings even with vim as EDITOR
bindkey -e

# Commands that start with a space are not put in history
setopt histignorespace

# Enable completions
# Using compinit -u (aka unsecure to allow for group writable zsh directories)
# There are insecure directories:
# /usr/local/Cellar/zsh/5.7.1/share/zsh/functions
# /usr/local/Cellar/zsh/5.7.1/share/zsh
# This is for multi-user homebrew installations: https://raeesbhatti.com/blog/configure-brew-for-multi-user-setup
autoload -U compinit && compinit -u

if which brew &>/dev/null
then
  [ -w $HOMEBREW_PREFIX/bin/brew ] && \
    [ ! -f $HOMEBREW_PREFIX/share/zsh/site-functions/_brew ] && \
    mkdir -p $HOMEBREW_PREFIX/share/zsh/site-functions &>/dev/null && \
    ln -s $HOMEBREW_PREFIX/Library/Contributions/brew_zsh_completion.zsh \
          $HOMEBREW_PREFIX/share/zsh/site-functions/_brew
  export FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
fi

# Enable regex moving
autoload -U zmv

# Style ZSH output
zstyle ':completion:*:descriptions' format '%U%B%F{red}%d%f%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Case insensitive globbing
setopt no_case_glob

# Expand parameters, commands and aritmatic in prompts
setopt prompt_subst

# Colorful prompt with Git and Subversion branch
autoload -U colors && colors

# more OS X/Bash-like word jumps
export WORDCHARS=''

source /usr/local/share/zsh/site-functions/_aws
source /usr/local/share/antigen/antigen.zsh

antigen bundle zdharma/fast-syntax-highlighting
antigen apply

eval "$(starship init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# export FZF_COMPLETION_TRIGGER=''
