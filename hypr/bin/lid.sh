#!/usr/bin/env bash

# Usage: `lid.sh open` or `lid.sh close`
# View logs: `journalctl -t lid.sh -f`

logger -t lid.sh "lid.sh called with: $1"

if [[ "$1" == "close" ]]; then
  # Only disable laptop screen if there's an external monitor connected
  monitor_count=$(hyprctl monitors all -j | jq length)
  logger -t lid.sh "Monitor count: $monitor_count"
  if [[ $monitor_count -gt 1 ]]; then
    logger -t lid.sh "Disabling eDP-1"
    hyprctl keyword monitor "eDP-1, disable"
  fi
elif [[ "$1" == "open" ]]; then
  # Always re-enable laptop screen when lid opens
  logger -t lid.sh "Enabling eDP-1"
  hyprctl keyword monitor "eDP-1, preferred, auto, 1.6"
fi

