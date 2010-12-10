
PACKAGES+=" uboot"
#hset uboot url "git!git://repo.or.cz/u-boot-openmoko/parrot-frames.git#uboot-df3120-git.tar.bz2"

configure-uboot() {
	configure make "$MINIFS_BOARD"_config
}

compile-uboot() {
	compile make CROSS_COMPILE="$CROSS-"
}

