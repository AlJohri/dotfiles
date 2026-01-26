#!/usr/bin/env bash

# Usage: toggle-resolution.sh [ipad|macbook|native]
#   ipad    - 2388x1668@60 with 2x scaling (iPad Pro 11")
#   macbook - 2560x1664@60 with 2x scaling (MacBook Air M2)
#   native  - Reset to monitors.conf defaults

set -euo pipefail

# Get the monitor name (assumes first monitor, adjust if needed)
MONITOR=$(hyprctl monitors -j | jq -r '.[0].name')
CURRENT_RES=$(hyprctl monitors -j | jq -r '"\(.[0].width)x\(.[0].height)"')

echo "Current monitor: $MONITOR"
echo "Current resolution: $CURRENT_RES"

case "${1:-}" in
    ipad)
        echo "Switching to iPad resolution: 2388x1668@60 with 2x scaling"
        hyprctl keyword monitor "$MONITOR,2388x1668@60,auto,2"
        ;;
    macbook)
        # MacBook Air M2: native 2560x1664
        # Scale 1.6 gives 1600x1040 logical
        echo "Switching to MacBook Air M2 resolution: 2560x1664@60 with 1.6x scaling"
        hyprctl keyword monitor "$MONITOR,2560x1664@60,auto,1.6"
        ;;
    native)
        echo "Resetting to monitors.conf defaults"
        hyprctl keyword source ~/.config/hypr/monitors.conf
        ;;
    *)
        echo "Usage: toggle-resolution.sh [ipad|macbook|native]"
        exit 1
        ;;
esac

# Show new resolution
sleep 0.5
NEW_RES=$(hyprctl monitors -j | jq -r '"\(.[0].width)x\(.[0].height)"')
echo "New resolution: $NEW_RES"
