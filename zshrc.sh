# Adapted from https://github.com/MikeMcQuaid/dotfiles/blob/master/zshrc.sh
debug_dotfiles=false
[ "$debug_dotfiles" = true ] && echo "loading zshrc..."

if [ "$debug_dotfiles" = true ]; then
	if [[ -o login ]]; then
	  echo "I'm a login shell"
	else
	  echo "I'm a non-login shell"
	fi

	if [ "$debug_dotfiles" = true ] && [[ -o interactive ]]; then
	  echo "I'm interactive"
	else
	  echo "I'm a non-interactive shell"
	fi
fi

# load shared shell configuration
source ~/.shrc

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
autoload -U compinit && compinit

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

git_branch() {
  GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  [ -n "$GIT_BRANCH" ] && echo "($GIT_BRANCH) "
}

svn_branch() {
  [ -d .svn ] || return
  SVN_INFO=$(svn info 2>/dev/null) || return
  SVN_BRANCH=$(echo $SVN_INFO | grep URL: | grep -oe '\(trunk\|branches/[^/]\+\|tags/[^/]\+\)')
  [ -n "$SVN_BRANCH" ] || return
  # Display tags intentionally so we don't write to them by mistake
  echo "(${SVN_BRANCH#branches/}) "
}

if [ $USER = "root" ]
then
  PROMPT='%{$fg_bold[magenta]%}%m %{$fg_bold[blue]%}# %b%f'
elif [ -n "${SSH_CONNECTION}" ]
then
  PROMPT='%{$fg_bold[cyan]%}%m %{$fg_bold[blue]%}# %b%f'
else
  PROMPT='%{$fg_bold[green]%}%m %{$fg_bold[blue]%}# %b%f'
fi
RPROMPT='%{$fg_bold[red]%}$(git_branch)%{$fg_bold[yellow]%}$(svn_branch)%b[%{$fg_bold[blue]%}%~%b%f]'

# more OS X/Bash-like word jumps
export WORDCHARS=''

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/zsh/site-functions/_aws
