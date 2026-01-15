#!/usr/bin/env bash

# is-lid-open.sh - Check if laptop lid is open
#
# Returns exit code 0 if lid is open, 1 if closed.
#
# Used by PAM to conditionally enable fingerprint authentication in clamshell mode.
# When the lid is closed, PAM skips fingerprint auth and falls back to password.
#
# PAM Configuration (added by setup-fingerprint-clamshell.sh):
#   auth [success=ignore default=1] pam_exec.so quiet /path/to/is-lid-open.sh
#
# This line is inserted BEFORE pam_fprintd.so in /etc/pam.d/sudo and /etc/pam.d/polkit-1.
# The PAM control flags work as follows:
#   - success=ignore: If script returns 0 (lid open), ignore result and continue to fprintd
#   - default=1: If script returns non-zero (lid closed), skip the next 1 line (fprintd)
#
# See also: setup-fingerprint-clamshell.sh

grep -q open /proc/acpi/button/lid/*/state 2>/dev/null
