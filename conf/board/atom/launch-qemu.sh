#!/bin/bash

vga=0x37a # 1280x800x32
vga=0x318 # 1024x768x24

# needs tap0 up
kvm -m 512 \
        -usb -usbdevice mouse -usbdevice keyboard \
        -kernel vmlinuz-bare.bin \
        -vga std -serial stdio \
        -net nic,model=ne2k_pci -net tap,ifname=tap0,script= \
        -append "init=/linuxrc console=ttyS0,115200 vga=0x318 root=/dev/sda rw quiet" \
        -hda minifs-full-ext.img

kvm -m 256 \
        -usb -usbdevice mouse -usbdevice keyboard \
        -kernel vmlinuz-bare.bin \
        -vga std -serial stdio \
        -net nic,model=ne2k_pci -net tap,ifname=tap0,script= \
        -append "rdinit=/linuxrc console=ttyS0,115200 vga=0x318 rw quiet"

kvm -m 32 \
        -kernel vmlinuz-full.bin \
        -vga none -serial stdio \
        -net nic,model=ne2k_pci -net tap,ifname=tap0,script= \
        -append "rdinit=/sbin/init console=ttyS0,115200 rw quiet"

mount /dev/sdh1 /mnt/arm && \
	cp /opt/minifs/build-atom/vmlinuz-full.bin /mnt/arm/vmlinuz && \
	umount /mnt/arm


X :0 -dpi 100 -ac -config xorg.conf.new &
X :0 -dpi 100 -ac &
GtkLauncher --display :0 'http://www.tvguide.co.uk/tv_channel_streams.asp?c=16' &

GtkLauncher --display :0 'http://www.bbc.co.uk/iplayer/' &

gdbserver :4444  GtkLauncher --display :0 'http://www.tvguide.co.uk/tv_channel_streams.asp?c=16' &

set solib-absolute-prefix /opt/minifs/build-atom/staging/
target extended-remote 10.0.0.96:4444

set solib-absolute-prefix /opt/minifs/build-yuckfan/staging/
target extended-remote 10.0.0.52:4444

