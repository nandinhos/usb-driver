# usb-driver: Data Flow

## Mount Flow (`up` command)

1. **Discovery**: `usbipd list` output is parsed to find storage devices.
2. **Selection**: User picks a device (or "All").
3. **Bridge**: `usbipd attach` is called. If "Not Shared", a `bind --force` UAC request is triggered.
4. **Stabilization**: A 5-second `sleep` allows the Windows driver to settle.
5. **Resolution**: `find_dev_by_vidpid` scans `/sys` to find the new `/dev/sdX` node.
6. **Validation**: `is_safe_device` checks if the partition is a system drive.
7. **Action**: `mount` attaches the filesystem to the target path.

## Unmount Flow (`down` command)

1. **Discovery**: `findmnt` scans `/mnt/usb-driver/`.
2. **Sync**: `sync` command is called to flush caches.
3. **Action**: `umount` releases the filesystem.
4. **Cleanup**: `usbipd detach` releases the hardware back to Windows.

## Error Handling Pattern

- **Exit Codes**: Commands return non-zero on failure.
- **Visual Feedback**: Using `log_error` and `log_warn` from `lib/logging.sh`.
- **Retry Logic**: `cmd_up` includes a retry loop for attachment when the device is "busy".
