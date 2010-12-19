#!/bin/bash

# Xvnc :1 -ac -geometry 320x240 -depth 16 -AlwaysShared -SecurityTypes None

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-v4t-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage

# target has tiny memory, use thumb, it's smaller
TARGET_CFLAGS="-Os -march=armv4t -mtune=arm920t -mthumb-interwork -mthumb "

board_set_versions() {
	hset linux version "2.6.36.1"
	TARGET_FS_SQUASH=0
	TARGET_INITRD=0
	TARGET_SHARED=1
	TARGET_FS_EXT_SIZE=16384

	hset uboot url "git!git://repo.or.cz/u-boot-openmoko/parrot-frames.git#uboot-df3120-git.tar.bz2"
}

board_prepare() {
	TARGET_PACKAGES+=" strace gdbserver libvncserver picocom uboot"
	TARGET_PACKAGES+=" bluez btscanner"
	if [ -d ~/Sources/Utils/fbvncslave ]; then
		TARGET_PACKAGES+=" fbvncslave"
	fi
}

df3120-deploy-linux-bare() {
	deploy-linux-bare
	cp "$BUILD"/kernel.ub "$ROOTFS"/linux
}

df3120-deploy-uboot() {
	# make sure the u-boot is aligned on 512 blocks, for mtd_debug
	deploy dd if=u-boot.bin of="$ROOTFS"/u-boot.bin bs=512 conv=sync
}

