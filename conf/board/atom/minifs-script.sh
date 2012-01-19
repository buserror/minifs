#!/bin/bash

#. "$CONF_BASE"/arch/x86_64.sh

TARGET_ARCH=x86_64
TARGET_FULL_ARCH=$TARGET_ARCH-atom-linux-gnu
TARGET_KERNEL_NAME=bzImage
TARGET_KERNEL_ARCH=x86_64
#TARGET_CFLAGS="-O2 -march=core2 -mtune=generic -mssse3 -mfpmath=sse -fomit-frame-pointer -pipe"
TARGET_LIBC_CFLAGS="-O2 -march=atom -mssse3 -fomit-frame-pointer -pipe"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS -fPIC"

board_set_versions() {
#	hset linux version "2.6.38.7"
	hset linux version "3.0.9"
	TARGET_FS_SQUASH=0
	TARGET_SHARED=1 
	TARGET_X11=1
	#TARGET_INITRD=1
}

board_prepare() {
	TARGET_PACKAGES+=" e2fsprogs gdbserver strace"
	TARGET_PACKAGES+=" libusb "

	TARGET_PACKAGES+=" curl libexpat libreadline libnetsnmp libgettext "

	# all of that for gtk
	TARGET_PACKAGES+=" libjpeg libpng libfreetype libfontconfig libpixman"
	
	# all of gtk JUST to get rsvg :/
	#TARGET_PACKAGES+=" librsvg"

	TARGET_PACKAGES+=" xorgserver xorginputmouse xorginputkeyboard nvidia"	
	TARGET_PACKAGES+=" libwebkit"
	TARGET_PACKAGES+=" flashplugin alsautils"
	
#	TARGET_PACKAGES+=" fbgrab"	
	TARGET_PACKAGES+=" libva-vdpau ffmpeg"
	TARGET_PACKAGES+=" gst-plugins-base gst-plugins-good gst-plugins-ugly"	
	TARGET_PACKAGES+=" vlc"	
		
	TARGET_PACKAGES+=" targettools libarchive"	
	
	TARGET_PACKAGES+=" firmware-rtl"
	
	hset openssl config "linux-x86_64"
}

atom-deploy-libgtk() {
	deploy-libgtk
	mkdir -p "$ROOTFS"/etc/gtk-2.0/
	cp "$CONFIG"/gdk-pixbuf.loaders "$ROOTFS"/etc/gtk-2.0/
}
