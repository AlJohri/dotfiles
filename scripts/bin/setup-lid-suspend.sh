#!/usr/bin/env bash

# setup-lid-suspend.sh - Disable suspend when laptop lid is closed on external power
#
# Prevents systemd-logind from suspending when the lid is closed while on
# external power, useful when running with external monitor in clamshell mode.
#
# This is needed because DPMS off + closed lid triggers suspend,
# which kills network (SSH, Tailscale).
#
# Behavior after running this script:
#   - On battery with lid closed → suspends (default behavior preserved)
#   - On external power with lid closed → stays awake
#
# To undo:
#   sudo rm /etc/systemd/logind.conf.d/lid.conf
#   sudo systemctl restart systemd-logind

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${YELLOW}$1${NC}"; }

CONF_DIR="/etc/systemd/logind.conf.d"
CONF_FILE="$CONF_DIR/lid.conf"

echo ""
print_success "Setting up lid suspend disable (external power only)"
echo ""

if [[ -f "$CONF_FILE" ]]; then
    print_info "Skipping (already configured at $CONF_FILE)"
else
    sudo mkdir -p "$CONF_DIR"
    sudo tee "$CONF_FILE" > /dev/null << 'EOF'
[Login]
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
    print_success "Created $CONF_FILE"
fi

echo ""
print_info "Note: Restart systemd-logind to apply (will terminate session):"
print_info "  sudo systemctl restart systemd-logind"
echo ""
