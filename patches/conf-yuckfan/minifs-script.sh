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
	TARGET_PACKAGES+=" librsvg"

	PACKAGES+=" libncurses lua"
}

hset url lua "http://www.lua.org/ftp/lua-5.1.4.tar.gz"
hset depends lua "libreadline libncurses"

configure-lua() {
	configure echo Done
}
compile-lua() {
	compile-generic linux CC=$GCC MYLDFLAGS="$LDFLAGS"
}
install-lua() {
	install-generic INSTALL_TOP=/usr
}


hset url libncurses "http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.7.tar.gz"
