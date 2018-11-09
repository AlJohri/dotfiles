# Adapted from https://github.com/MikeMcQuaid/dotfiles/blob/master/bashrc.sh

source ~/.shrc

# History
export HISTFILE=~/.bash_history
export HISTCONTROL=ignoredups
export PROMPT_COMMAND='history -a'
export HISTIGNORE="&:ls:[bf]g:exit"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
