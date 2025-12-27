#!/usr/bin/env bash

# Usage: `lid.sh open` or `lid.sh close` or `lid.sh check`
# View logs: `journalctl -t lid.sh -f`

logger -t lid.sh "lid.sh called with: $1"

action="$1"

# "check" reads current lid state and converts to open/close
if [[ "$action" == "check" ]]; then
  lid_state=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}')
  logger -t lid.sh "Lid state check: $lid_state"
  if [[ "$lid_state" == "closed" ]]; then
    action="close"
  else
    action="open"
  fi
fi

if [[ "$action" == "close" ]]; then
  # Only disable laptop screen if there's an external monitor connected
  monitor_count=$(hyprctl monitors all -j | jq length)
  logger -t lid.sh "Monitor count: $monitor_count"
  if [[ $monitor_count -gt 1 ]]; then
    logger -t lid.sh "Disabling eDP-1"
    hyprctl keyword monitor "eDP-1, disable"
  fi
elif [[ "$action" == "open" ]]; then
  # Always re-enable laptop screen when lid opens
  logger -t lid.sh "Enabling eDP-1"
  hyprctl keyword monitor "eDP-1, preferred, auto, 1.6"
fi

