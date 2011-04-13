#!/bin/bash

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-cortexa8-linux-gnueabi
TARGET_KERNEL_NAME=uImage
TARGET_KERNEL_ARCH=arm
TARGET_CFLAGS="-O2 -mcpu=cortex-a8 -mfpu=neon -fPIC -ftree-vectorize -mfloat-abi=soft -fsingle-precision-constant -pipe"

board_set_versions() {
	hset linux version "2.6.35.6"
	TARGET_FS_SQUASH=0
	TARGET_FS_EXT_SIZE=262144
	TARGET_SHARED=1 
	#TARGET_DIRECTFB=0
	TARGET_X11=1
	#TARGET_INITRD=1
}

board_prepare() {
	TARGET_PACKAGES+=" e2fsprogs gdbserver strace"
	TARGET_PACKAGES+=" libusb usbutils"

	TARGET_PACKAGES+=" curl libexpat libreadline libnetsnmp libgettext hotplug2"

	# all of that for gtk
	TARGET_PACKAGES+=" libjpeg libpng libfreetype libfontconfig libpixman"
	TARGET_PACKAGES+=" libts $DIRECTFB_PACKAGE"
	
	# all of gtk JUST to get rsvg :/
	TARGET_PACKAGES+=" librsvg"

	TARGET_PACKAGES+=" xorgserver"	
	TARGET_PACKAGES+=" libwebkit"
}
