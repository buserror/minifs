#!/bin/bash

TARGET_META_ARCH=armv5

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-v5-linux-uclibcgnueabi
TARGET_KERNEL_NAME=zImage
# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/
TARGET_KERNEL_DTB=${TARGET_KERNEL_DTB:-imx23-olinuxino}
TARGET_KERNEL_CMDLINE=${TARGET_KERNEL_CMDLINE:-"console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc quiet"}
#TARGET_LIBC_CFLAGS="-g -O2 -mcpu=arm926ej-s -fPIC"
TARGET_LIBC_CFLAGS="-g -O2 -march=armv5te -mtune=arm926ej-s -fPIC -mthumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"

board_set_versions() {
	hset linux version "3.7"
	TARGET_FS_SQUASH=0
	TARGET_FS_EXT2=1
	TARGET_SHARED=1 
#	TARGET_X11=1
	#TARGET_INITRD=1
#	NEEDED_HOST_COMMANDS+=" mkimage"
}

board_prepare() {
	TARGET_PACKAGES+=" gdbserver strace"
#	TARGET_PACKAGES+=" libusb "
	TARGET_PACKAGES+=" curl wpa-supplicant wireless-tools"
	TARGET_PACKAGES+=" firmware-rtl"
	TARGET_PACKAGES+=" openssh sshfs"

	TARGET_PACKAGES+=" targettools"
	TARGET_PACKAGES+=" kexec-tools"
	
	TARGET_PACKAGES+=" linux-dtb elftosb"
	TARGET_PACKAGES+=" libsdl sdlvoxel sdlplasma libpng libsdlimage kobodeluxe"
	TARGET_PACKAGES+=" mplayer"
	TARGET_PACKAGES+=" node"
}

bard_local() {
	tftp -g -r linux -l /tmp//linux 192.168.2.129 &&	kexec --append="$(cat /proc/cmdline)" --force /tmp/linux
	tftp -g -r linux -l /tmp/linux 192.168.2.129 &&	kexec --append="console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc" --force --no-ifdown /tmp/linux
}
