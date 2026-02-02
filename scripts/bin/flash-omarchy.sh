#!/usr/bin/env bash
set -euo pipefail

# Flash the latest Omarchy ISO to a USB drive using caligula.

# Check required tools
for cmd in caligula lsblk; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is required but not found." >&2
        exit 1
    fi
done

# Download ISO
iso_file=$(download-omarchy-iso.sh)

# Detect USB drive
echo "==> Looking for OMARCHY_* USB drives..."
usb_mounts=(/run/media/"$USER"/OMARCHY_*)
if [[ ! -d "${usb_mounts[0]:-}" ]]; then
    echo "Error: No mounted OMARCHY_* USB drive found at /run/media/$USER/." >&2
    echo "       Plug in a USB drive labeled OMARCHY_* and try again." >&2
    exit 1
fi

mount_point="${usb_mounts[0]}"
partition=$(findmnt -n -o SOURCE "$mount_point")
if [[ -z "$partition" ]]; then
    echo "Error: Could not determine block device for $mount_point." >&2
    exit 1
fi

device="/dev/$(lsblk -no PKNAME "$partition")"
if [[ "$device" == "/dev/" ]]; then
    echo "Error: Could not determine parent device for $partition." >&2
    exit 1
fi

# Confirm with user
echo ""
echo "==> Target device: $device"
lsblk -o NAME,SIZE,MODEL,VENDOR "$device"
echo ""
read -rp "Flash $iso_file to $device? This will ERASE ALL DATA. [y/N] " confirm
if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 0
fi

# Unmount all partitions on the device
echo "==> Unmounting partitions on $device..."
for part in $(lsblk -nlo NAME "$device" | tail -n +2); do
    if findmnt -n "/dev/$part" &> /dev/null; then
        echo "    Unmounting /dev/$part"
        umount "/dev/$part"
    fi
done

# Flash
echo "==> Flashing ISO to $device..."
caligula burn "$iso_file" -o "$device"

# Sync and safely eject
echo "==> Syncing..."
sync
echo "==> Ejecting $device..."
udisksctl power-off -b "$device"
echo "==> Done! Safe to remove the USB drive."
