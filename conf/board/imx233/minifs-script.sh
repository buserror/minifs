#!/bin/bash

. "$CONF_BASE"/arch/armv5.sh

MINIFS_BOARD_ROLE+=" mxs"

TARGET_KERNEL_NAME=zImage

# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/
TARGET_KERNEL_DTB=${TARGET_KERNEL_DTB:-imx23-olinuxino}
TARGET_KERNEL_CMDLINE=${TARGET_KERNEL_CMDLINE:-"console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc quiet"}

board_set_versions() {
	hset linux version "3.8"
	TARGET_FS_SQUASH=0
	TARGET_FS_EXT2=1
	TARGET_SHARED=1 
}

board_prepare() {
	TARGET_PACKAGES+=" gdbserver strace"
	TARGET_PACKAGES+=" curl wpa-supplicant wireless-tools"
	TARGET_PACKAGES+=" firmware-rtl firmware-ralink"
	TARGET_PACKAGES+=" openssh sshfs"

	TARGET_PACKAGES+=" targettools"
	TARGET_PACKAGES+=" kexec-tools"
	
	TARGET_PACKAGES+=" linux-dtb elftosb"
#	TARGET_PACKAGES+=" libsdl sdlvoxel sdlplasma libpng libsdlimage kobodeluxe mplayer"
#	TARGET_PACKAGES+=" font-bitstream-vera rrdtool"
}

bard_local() {
	# how to use kexec from the board to launch a new kernel
	tftp -g -r linux -l /tmp//linux 192.168.2.129 &&	kexec --append="$(cat /proc/cmdline)" --force /tmp/linux
	tftp -g -r linux -l /tmp/linux 192.168.2.129 &&	kexec --append="console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc" --force --no-ifdown /tmp/linux

	# how to launch this in qemu
	./arm-softmmu/qemu-system-arm  -M imx233o -m 64M -kernel /opt/minifs/build-imx233/vmlinuz-bare.dtb -monitor telnet::4444,server,nowait -serial stdio -display none -sd /opt/olimex/basic.img -usb -snapshot
}
