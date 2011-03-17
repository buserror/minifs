#!/bin/bash

TARGET_ARCH=i586
TARGET_FULL_ARCH=$TARGET_ARCH-atom-linux-gnu
TARGET_KERNEL_NAME=bzImage
TARGET_KERNEL_ARCH=x86
TARGET_CFLAGS="-O2 -march=core2 -mtune=generic -mssse3 -mfpmath=sse -fomit-frame-pointer -pipe"

board_set_versions() {
	hset linux version "2.6.38"
	TARGET_FS_SQUASH=0
	TARGET_FS_EXT_SIZE=262144
	TARGET_SHARED=1 
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

	TARGET_PACKAGES+=" xorgserver nvidia"	
	TARGET_PACKAGES+=" libwebkit"
	TARGET_PACKAGES+=" flashplugin alsautils"
	
	TARGET_PACKAGES+=" fbgrab"	
	
	TARGET_PACKAGES+=" libetpan"	

	TARGET_PACKAGES+=" syslinux"	
}

atom-deploy-libgtk() {
	deploy-libgtk
	cp "$CONFIG"/gdk-pixbuf.loaders "$ROOTFS"/etc/gtk-2.0/
}
