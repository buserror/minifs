#!/bin/bash


TARGET_META_ARCH=armv6

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-v6-linux-uclibcgnueabi
#TARGET_KERNEL_NAME=uImage
TARGET_LIBC_CFLAGS="-g -O2 -march=armv6 -mfloat-abi=hard -mfpu=vfp -fPIC -mthumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"

TARGET_KERNEL_NAME=zImage

board_set_versions() {	
	TARGET_FS_SQUASH=0
	TARGET_FS_EXT2=1
	TARGET_SHARED=1 
}

board_prepare() {
	hset linux version "3.6.11"
	hset linux url "https://github.com/raspberrypi/linux/archive/rpi-3.6.y.tar.gz"

	TARGET_PACKAGES+=" gdbserver strace"
	TARGET_PACKAGES+=" curl wpa-supplicant wireless-tools"
	TARGET_PACKAGES+=" firmware-rtl firmware-ralink"
	TARGET_PACKAGES+=" openssh sshfs"

	TARGET_PACKAGES+=" targettools"
	TARGET_PACKAGES+=" kexec-tools"
	
}
