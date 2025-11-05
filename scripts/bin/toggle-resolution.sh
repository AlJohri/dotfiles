#!/usr/bin/env bash

# Get the monitor name (assumes first monitor, adjust if needed)
MONITOR=$(hyprctl monitors -j | jq -r '.[0].name')

# Get current resolution
CURRENT_RES=$(hyprctl monitors -j | jq -r '"\(.[0].width)x\(.[0].height)"')

# Define resolutions
NATIVE_RES="3440x1440@59.97"
IPAD_RES="2388x1668@60"

echo "Current monitor: $MONITOR"
echo "Current resolution: $CURRENT_RES"

# Toggle resolution
if [[ "$CURRENT_RES" == "2388x1668" ]]; then
    echo "Switching to native resolution: $NATIVE_RES with 1x scaling"
    hyprctl keyword monitor "$MONITOR,$NATIVE_RES,auto,1"
else
    echo "Switching to iPad resolution: $IPAD_RES with 2x scaling"
    hyprctl keyword monitor "$MONITOR,$IPAD_RES,auto,2"
fi

# Show new resolution
sleep 0.5
NEW_RES=$(hyprctl monitors -j | jq -r '"\(.[0].width)x\(.[0].height)"')
echo "New resolution: $NEW_RES"
