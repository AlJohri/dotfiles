# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Auto-launch fish shell if in interactive zsh
if command -v fish &> /dev/null; then
  if [[ $(ps -p $PPID -o comm=) != "fish" && -z ${ZSH_EXECUTION_STRING} && ${SHLVL} == 1 ]]; then
    exec fish -l
  fi
fi

# gog (gogcli) keyring env
[ -r "$HOME/.config/gogcli/env.sh" ] && . "$HOME/.config/gogcli/env.sh"
