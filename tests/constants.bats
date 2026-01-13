#!/usr/bin/env bats
# tests/constants.bats - Tests for constants and configuration

load test_helper

@test "SUPPORTED_FS includes ext4" {
    [[ "$SUPPORTED_FS" =~ ext4 ]]
}

@test "SUPPORTED_FS includes vfat" {
    [[ "$SUPPORTED_FS" =~ vfat ]]
}

@test "SUPPORTED_FS includes ntfs" {
    [[ "$SUPPORTED_FS" =~ ntfs ]]
}

@test "USBIPD_EXE path is set" {
    [ -n "$USBIPD_EXE" ]
}

@test "DEFAULT_MOUNT_POINT is /mnt/usb-driver" {
    [ "$DEFAULT_MOUNT_POINT" = "/mnt/usb-driver" ]
}

@test "ATTACH_RETRIES defaults to 3" {
    [ "$ATTACH_RETRIES" = "3" ]
}

@test "ATTACH_DELAY defaults to 3" {
    [ "$ATTACH_DELAY" = "3" ]
}
