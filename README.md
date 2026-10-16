# nabu-serial

**English** | 中文

USB CDC-ACM **serial debug console** for the Xiaomi Pad 5 (`nabu`): a configfs
gadget that exposes the kernel log to a host PC over the USB-C port, so a hang
(black panel, dead SSH) can still be captured.

## How it works

- The kernel builds the configfs CDC-ACM function
  (`CONFIG_USB_CONFIGFS_ACM`, see `config/nabu-serial.config`) but **not** the
  legacy `CONFIG_USB_G_SERIAL`, so `/dev/ttyGS0` only appears once userspace
  builds the gadget.
- `libexec/nabu-usb-console.sh` (run by `system/nabu-usb-console.service`)
  creates `acm.usb0` and binds it to the first UDC; the host then sees
  `/dev/ttyACM*`.
- The consumer's kernel command line carries `console=ttyGS0` (nabu-main's
  `debian/config/debian.cmdline`), so kernel printk reaches the gadget.  The
  ttyGS console has `CON_PRINTBUFFER`, so the whole boot ring buffer is
  replayed as soon as the gadget is created.
- `serial-getty@ttyGS0.service` must stay **masked**: `console=ttyGS0` would
  otherwise make systemd start the generator's getty, and because ttyGS0 only
  appears once a host enumerates the gadget its `dev-ttyGS0.device` dependency
  stalls boot for the full 90 s device timeout without a host cable.

## Contents

```text
config/nabu-serial.config
libexec/nabu-usb-console.sh
system/nabu-usb-console.service
```

## Capture

On the host PC attached to the tablet's USB-C port:

```sh
ls /dev/ttyACM*
nabu-main/debian/capture-serial.sh -t -o nabu-serial.log
```

See `nabu-main/debian/config/USB-CONSOLE.md` for details (the USB-C port is
forced to device role on this build, and the charger must be disabled — build a
product that drops `nabu-power` — so the port is free for the gadget).
