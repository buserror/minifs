
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
compile-uboot-local() {
	$MAKE $MAKE_ARGUMENTS  CROSS_COMPILE="$CROSS-" &&
		$MAKE CROSS_COMPILE="$CROSS-" \
			TOPDIR=../.. \
			CPPFLAGS="$CFLAGS -DUSE_HOSTCC -static -I../../include" \
			-C tools/env
}
compile-uboot() {
	compile compile-uboot-local
}
install-uboot-local() {
	if [ -x tools/mkimage ]; then
		mkdir -p "$STAGING_TOOLS"/bin/
		cp tools/mkimage "$STAGING_TOOLS"/bin/
	fi
	if [ -x tools/env/fw_printenv ]; then
		mkdir -p "$STAGING_USR"/bin/ "$STAGING"/etc/
		cp tools/env/fw_printenv "$STAGING_USR"/bin/
		cp tools/env/fw_env.config "$STAGING"/etc/
	fi
}
install-uboot() {
	log_install install-uboot-local
}
deploy-uboot() {
	mkdir -p "$ROOTFS"/bin/
	if [ -x "$STAGING_USR"/bin/fw_printenv ]; then
		deploy cp "$STAGING_USR"/bin/fw_printenv "$ROOTFS"/bin/
	fi	
}
