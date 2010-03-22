#!/bin/bash

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-v4t-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage
TARGET_CFLAGS="-Os -march=armv4t -mtune=arm920t -mthumb-interwork -mthumb "

board_set_versions() {
	VERSION_linux=2.6.32.7
	# for a >64Mb nand with 2k blocks and 128k erase blocks
	TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"
	TARGET_FS_EXT_SIZE=32768
	TARGET_SHARED=1
	TARGET_INITRD=1
}

board_prepare() {
	TARGET_PACKAGES+=" mtd_utils"
	TARGET_PACKAGES+=" libftdi lua"

	TARGET_PACKAGES+=" curl libexpat libreadline libiconv libnetsnmp libgettext"

	# all of thqt for gtk
	TARGET_PACKAGES+=" libjpeg libpng libfreetype libfontconfig libpixman"
	TARGET_PACKAGES+=" libts libdirectfb"
	TARGET_PACKAGES+=" libgtk"
	
	# all of gtk JUST to get rsvg :/
	TARGET_PACKAGES+=" librsvg font-bitstream-vera libim"

	if [ -d $HOME/Sources/Utils/yuckfan ]; then
		TARGET_PACKAGES+=" yuckfan gdbserver"
	fi
	
	PACKAGES=$(echo $PACKAGES|sed 's|librsvg|librsvg yuckfan|')

	# get snapshot version of cairo
	hset url libcairo "http://cairographics.org/snapshots/cairo-1.9.6.tar.gz"
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

hset url yuckfan "none"
hset dir yuckfan "."
hset depends yuckfan "toluapp"
hset dir destdir "none"

configure-yuckfan() {
	configure echo Done
}
compile-yuckfan-local() {
	set -x
	pushd $HOME/Sources/Utils/yuckfan
	$MAKE -j8  \
		DESTDIR="$STAGING"/opt/yf \
		CROSS_COMPILE="$TARGET_FULL_ARCH"- \
		CROSS_PATH="$TOOLCHAIN"/bin \
		EXTRA_LDFLAGS="$LDFLAGS_RLINK" \
		EXTRA_CFLAGS="$CFLAGS" \
		install
	popd
	set +x
}
compile-yuckfan() {
	compile compile-yuckfan-local
}
install-yuckfan() {
	log_install echo Done
}
deploy-yuckfan() {
	ROOTFS_PLUGINS+="$ROOTFS/opt/yf:"
	
	deploy rsync -av "$STAGING"/opt/yf "$ROOTFS"/opt/
}

