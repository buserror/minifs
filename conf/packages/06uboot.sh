
PACKAGES+=" uboot"
#hset uboot url "git!git://repo.or.cz/u-boot-openmoko/parrot-frames.git#uboot-df3120-git.tar.bz2"

configure-uboot() {
	configure make "$MINIFS_BOARD"_config
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

