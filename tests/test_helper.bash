#!/usr/bin/env bash
# tests/test_helper.bash - Common setup for all tests

# Get project root
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

# Source all libraries
source "$PROJECT_ROOT/lib/constants.sh"
source "$PROJECT_ROOT/lib/logging.sh"

# Disable colors for tests (cleaner output)
RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''

# Mock functions for testing without real hardware
mock_lsblk() {
    cat << 'EOF'
NAME   SIZE FSTYPE LABEL          TRAN MOUNTPOINT
sda    500G ext4   System              /
sdb     16G vfat   PENDRIVE       usb  
sdb1    16G vfat   PENDRIVE       usb  /mnt/usb-driver/PENDRIVE
sdc      1T ntfs   Windows        sata 
sdd      8G ext4   BACKUP         usb  
EOF
}

mock_usbipd_list() {
    cat << 'EOF'
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
2-6    0bda:555b  Integrated Webcam                                             Not shared
2-15   058f:6387  USB Mass Storage Device                                       Shared (forced)
2-16   24a9:205a  USB Mass Storage Device                                       Attached
EOF
}
