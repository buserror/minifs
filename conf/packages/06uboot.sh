
PACKAGES+=" uboot"
# uboot URL is set by each board, not here
#hset uboot url "git!git://repo.or.cz/u-boot-openmoko/parrot-frames.git#uboot-df3120-git.tar.bz2"

configure-uboot() {
	local arch=$MINIFS_BOARD_UBOOT
	if [ "$arch" = "" ];then
		arch=$MINIFS_BOARD
	fi
	configure make "$arch"_config
}

compile-uboot() {
	compile make CROSS_COMPILE="$CROSS-"
}

install-uboot-local() {
	if [ -x tools/mkimage ]; then
		cp tools/mkimage "$STAGING_TOOLS"/bin/
	fi
}

install-uboot() {
	log_install install-uboot-local
}

