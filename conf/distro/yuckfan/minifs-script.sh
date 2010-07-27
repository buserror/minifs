#!/bin/bash

distro_set_versions() {
	TARGET_FS_EXT_SIZE=32768
	TARGET_SHARED=1
	TARGET_INITRD=1
	TARGET_FS_SQUASH=0
}

distro_prepare() {
	TARGET_PACKAGES+=" lua libcurl libexpat libreadline libiconv libnetsnmp libgettext"

	# all of that for gtk
	TARGET_PACKAGES+=" libjpeg libpng libfreetype libfontconfig libpixman"
	TARGET_PACKAGES+=" libts libdirectfb"
	TARGET_PACKAGES+=" libgtk"
	
	# all of gtk JUST to get rsvg :/
	TARGET_PACKAGES+=" librsvg font-bitstream-vera libim"

	if [ -d $HOME/Sources/Utils/yuckfan ]; then
		TARGET_PACKAGES+=" yuckfan"
	fi
	if [ -d $HOME/Sources/Utils/sensors ]; then
		TARGET_PACKAGES+=" sensors"
	fi
	
	PACKAGES=$(echo $PACKAGES|sed 's|librsvg|librsvg yuckfan|')

	# get snapshot version of cairo
	hset libcairo url "http://cairographics.org/snapshots/cairo-1.9.6.tar.gz"
}

yuckfan-deploy-libdirectfb() {
	deploy echo Skipping Directfb deploy
}
yuckfan-deploy-libgtk() {
	deploy echo Skipping GTK deploy
}
yuckfan-deploy-librsvg() {
	deploy echo Skipping RSVG tools install
}
yuckfan-deploy-libfontconfig() {
	deploy echo Skipping libfontconfig tools install
	#deploy-libfontconfig
}

yuckfan-sharedlibs-cleanup() {
	echo Cleanup up for yuckfan
	rm -rf "$ROOTFS"/usr/lib/directfb-1.4-0-pure \
		"$ROOTFS"/usr/lib/mozilla \
		"$ROOTFS"/usr/lib/glib-2.0 \
		"$ROOTFS"/usr/lib/gio \
		"$ROOTFS"/usr/lib/gettext \
		"$ROOTFS"/usr/lib/gtk-2.0/include \
		"$ROOTFS"/usr/lib/gtk-2.0/modules \
		"$ROOTFS"/usr/lib/gtk-2.0/2.10.0/printbackends
}

hset yuckfan url "none"
hset yuckfan dir "."
hset yuckfan depends "toluapp"
hset yuckfan destdir "$STAGING"/opt/yf

configure-yuckfan() {
	configure echo Done
}
compile-yuckfan() {
	compile-generic \
		-C $HOME/Sources/Utils/yuckfan \
		CROSS_COMPILE="$TARGET_FULL_ARCH"- \
		EXTRA_LDFLAGS="$LDFLAGS_RLINK" \
		EXTRA_CFLAGS="$CFLAGS" 
}
install-yuckfan() {
	install-generic \
		-C $HOME/Sources/Utils/yuckfan \
		CROSS_COMPILE="$TARGET_FULL_ARCH"-
}
deploy-yuckfan() {
	ROOTFS_PLUGINS+="$ROOTFS/opt/yf:"
	
	deploy rsync -av "$STAGING"/opt/yf "$ROOTFS"/opt/
}

