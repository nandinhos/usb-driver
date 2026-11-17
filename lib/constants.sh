#!/bin/bash
# lib/constants.sh - Centralized constants for usb-driver
# All configurable values and defaults should be defined here.
# shellcheck disable=SC2034 # These constants are used by other sourced files

# =========================
# Paths
# =========================
DEFAULT_MOUNT_POINT="/mnt/usb-driver"
LEGACY_MOUNT_POINT="/mnt/bkp-pendrive"
CONFIG_DIR="$HOME/.config/usb-driver"
VERSION="0.9.0"

# =========================
# usbipd-win
# =========================
USBIPD_EXE='C:\Program Files\usbipd-win\usbipd.exe'

# =========================
# Retry & Timeout Settings
# =========================
ATTACH_RETRIES="${ATTACH_RETRIES:-3}"
ATTACH_DELAY="${ATTACH_DELAY:-3}"
STABILIZATION_DELAY="${STABILIZATION_DELAY:-5}"
DEVICE_DETECTION_RETRIES="${DEVICE_DETECTION_RETRIES:-15}"

# =========================
# Filesystem Support
# =========================
SUPPORTED_FS="ext4|ntfs|vfat|exfat|fuseblk"

# =========================
# USB Device Filters
# =========================
USB_STORAGE_FILTER="Mass Storage|Armazenamento|UAS|SCSI"

# =========================
# Security & Validation Helpers
# =========================

# Validate Windows USBIPD BUSID format (e.g., 2-4 or 1-2.3)
validate_busid() {
    local busid="$1"
    [[ "$busid" =~ ^[0-9]+-[0-9]+(\.[0-9]+)*$ ]]
}

# Sanitize mount directory name (whitelist alphanumeric, dot, underscore, hyphen)
sanitize_mount_name() {
    local raw="$1"
    local fallback="${2:-usb-device}"
    local clean
    clean=$(printf '%s' "$raw" | tr -cd '[:alnum:]._-')
    # Reject empty, '.', '..', or names starting with '-'
    if [[ -z "$clean" || "$clean" == "." || "$clean" == ".." || "$clean" == -* ]]; then
        clean=$(printf '%s' "$fallback" | tr -cd '[:alnum:]._-')
    fi
    if [[ -z "$clean" || "$clean" == "." || "$clean" == ".." ]]; then
        clean="usb-device"
    fi
    printf '%s' "$clean"
}

# Escape string for safe JSON output
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# Safely parse key=value config without executing arbitrary shell code
load_safe_config() {
    local cfg_file="$1"
    [ -f "$cfg_file" ] || return 0
    local line key val
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and blank lines
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        if [[ "$line" =~ ^[[:space:]]*(MOUNT_POINT|PENDRIVE_LABEL|LOG_DIR)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            # Strip matching surrounding quotes
            val="${val#\"}"
            val="${val%\"}"
            val="${val#\'}"
            val="${val%\'}"
            case "$key" in
                MOUNT_POINT)
                    if [[ "$val" =~ ^/[[:alnum:]._/-]+$ && "$val" != *".."* ]]; then
                        MOUNT_POINT="$val"
                    fi
                    ;;
                PENDRIVE_LABEL)
                    PENDRIVE_LABEL=$(printf '%s' "$val" | tr -cd '[:alnum:]._ -')
                    ;;
                LOG_DIR)
                    LOG_DIR="$val"
                    ;;
            esac
        fi
    done < "$cfg_file"
}

# =========================
# Helper: Parse usbipd state
# Input: A line from `usbipd list`
# Output: Prints one of: Attached, Shared, NotShared
# =========================
parse_usbipd_state() {
    local line="$1"
    
    if echo "$line" | grep -qi "Attached"; then
        echo "Attached"
    elif echo "$line" | grep -qi "Not shared"; then
        echo "NotShared"
    elif echo "$line" | grep -qi "Shared"; then
        echo "Shared"
    else
        # Fallback: extract last word
        echo "$line" | awk '{print $NF}'
    fi
}
