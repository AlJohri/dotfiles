#!/usr/bin/env bash

# setup-fingerprint-clamshell.sh - Configure PAM to skip fingerprint auth when lid is closed
#
# This script modifies PAM configuration to conditionally disable fingerprint authentication
# when the laptop lid is closed (clamshell mode). Instead of waiting ~20s for fingerprint
# timeout, it falls back immediately to password authentication.
#
# How it works:
#   Inserts a pam_exec.so line BEFORE pam_fprintd.so that runs is-lid-open.sh:
#     auth [success=ignore default=1] pam_exec.so quiet /path/to/is-lid-open.sh
#
#   - Lid open:  is-lid-open.sh returns 0 → PAM continues to fingerprint auth
#   - Lid closed: is-lid-open.sh returns 1 → PAM skips fingerprint, uses password
#
# Files modified:
#   - /etc/pam.d/sudo     - terminal sudo commands
#   - /etc/pam.d/polkit-1 - graphical privilege escalation dialogs (e.g., GUI apps requesting root)
#
# Both files need to be modified because they handle different authentication contexts.
# This mirrors what omarchy-setup-fingerprint does.
#
# To undo:
#   sudo sed -i '/is-lid-open\.sh/d' /etc/pam.d/sudo /etc/pam.d/polkit-1
#
# Note: Running omarchy-setup-fingerprint will overwrite these changes.
#       Re-run this script afterward to restore clamshell mode support.
#
# References:
#   - https://heywoodlh.io/disable-fprint-clamshell-laptop/
#   - https://unix.stackexchange.com/questions/678609/

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${YELLOW}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }

# Find is-lid-open.sh via PATH
LID_SCRIPT=$(which is-lid-open.sh 2>/dev/null || true)

if [[ -z "$LID_SCRIPT" ]]; then
    print_error "Error: is-lid-open.sh not found in PATH"
    print_info "Make sure to run 'make stow-omarchy' first to symlink scripts to ~/bin"
    exit 1
fi

print_info "Using lid check script: $LID_SCRIPT"

# The PAM line to insert (before pam_fprintd.so)
PAM_LINE="auth [success=ignore default=1] pam_exec.so quiet $LID_SCRIPT"

configure_pam_file() {
    local pam_file="$1"

    if [[ ! -f "$pam_file" ]]; then
        print_info "Skipping $pam_file (file does not exist)"
        return
    fi

    # Check if fingerprint auth is configured
    if ! grep -q 'pam_fprintd\.so' "$pam_file"; then
        print_info "Skipping $pam_file (fingerprint auth not enabled)"
        return
    fi

    # Check if lid check is already configured
    if grep -q 'is-lid-open\.sh' "$pam_file"; then
        print_info "Skipping $pam_file (lid check already configured)"
        return
    fi

    print_info "Configuring $pam_file..."

    # Insert the lid check line before pam_fprintd.so
    sudo sed -i "/pam_fprintd\.so/i $PAM_LINE" "$pam_file"

    print_success "Configured $pam_file"
}

echo ""
print_success "Setting up fingerprint clamshell mode support"
echo ""

configure_pam_file "/etc/pam.d/sudo"
configure_pam_file "/etc/pam.d/polkit-1"

echo ""
print_success "Done! Fingerprint auth will now be skipped when lid is closed."
print_info "Test with: sudo echo test"
echo ""
