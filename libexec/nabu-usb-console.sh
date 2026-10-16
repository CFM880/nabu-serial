#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Create a CDC-ACM USB gadget so a host PC can follow the kernel console even
# when the device wedges (black panel, no SSH).
#
# The kernel enables the configfs CDC-ACM function (CONFIG_USB_CONFIGFS_ACM,
# see config/nabu-serial.config) but not the legacy CONFIG_USB_G_SERIAL, so
# /dev/ttyGS0 is only created once userspace builds the gadget here.  With the
# gadget bound and console=ttyGS0 on the kernel command line, printk reaches
# the host as /dev/ttyACM*; capture it with nabu-main/debian/capture-serial.sh.
set -eu

GADGET=/sys/kernel/config/usb_gadget/nabu-console
UDC=$(ls /sys/class/udc 2>/dev/null | head -n1)

if [ -z "$UDC" ]; then
	echo "nabu-usb-console: no USB device controller" >&2
	exit 0
fi

if [ -d "$GADGET" ]; then
	printf '' > "$GADGET/UDC" 2>/dev/null || true
	rm -f "$GADGET/configs/c.1/acm.usb0"
	rmdir "$GADGET/configs/c.1/strings/0x409" 2>/dev/null || true
	rmdir "$GADGET/configs/c.1" 2>/dev/null || true
	rmdir "$GADGET/functions/acm.usb0" 2>/dev/null || true
	rmdir "$GADGET/strings/0x409" 2>/dev/null || true
	rmdir "$GADGET" 2>/dev/null || true
fi

mkdir -p "$GADGET"
cd "$GADGET"
echo 0x1d6b > idVendor
echo 0x0104 > idProduct

mkdir -p strings/0x409
echo "nabu" > strings/0x409/manufacturer
echo "nabu-console" > strings/0x409/product
echo "$(cat /sys/class/net/lo/address 2>/dev/null || echo 0123456789)" \
	> strings/0x409/serialnumber

mkdir -p configs/c.1/strings/0x409
echo "acm" > configs/c.1/strings/0x409/configuration

mkdir -p functions/acm.usb0
ln -s functions/acm.usb0 configs/c.1/

echo "$UDC" > UDC
echo "nabu-usb-console: bound $UDC"
