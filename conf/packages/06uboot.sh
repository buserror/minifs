
PACKAGES+=" uboot"
# uboot URL is set by each board, not here
#hset uboot url "git!git://repo.or.cz/u-boot-openmoko/parrot-frames.git#uboot-df3120-git.tar.bz2"
hset uboot target "u-boot.bin"
hset uboot output "$STAGING/uboot-obj"

configure-uboot() {
	local arch=$(hget uboot board)
	mkdir -p $(hget uboot output)
	if [ "$arch" = "" ];then
		arch=$MINIFS_BOARD
		echo WARNING uboot needs an explicit board name
	fi
	configure make O=$(hget uboot output) "$arch"_config
}
compile-uboot-local() {
	$MAKE $MAKE_ARGUMENTS \
			O=$(hget uboot output) \
			CROSS_COMPILE="$CROSS-" \
			$(hget uboot target)
}
compile-uboot() {
	compile compile-uboot-local
}
install-uboot-local() {
	pushd $(hget uboot output)
	if [ -x tools/mkimage ]; then
		mkdir -p "$STAGING_TOOLS"/bin/ "$ROOTFS"/sbin/
		cp tools/mkimage "$STAGING_TOOLS"/bin/
	fi
	if [ -x tools/env/fw_printenv ]; then
		mkdir -p "$STAGING_USR"/bin/ "$STAGING"/etc/
		cp tools/env/fw_printenv "$STAGING_USR"/bin/
		cp tools/env/fw_env.config "$STAGING"/etc/
		cp tools/env/fw_printenv "$ROOTFS"/sbin/
	fi
	popd
}
install-uboot() {
	log_install install-uboot-local
}

deploy-uboot-local() {
	if [ "$(hget uboot deploy-target)" != "" ]; then
		$MAKE $MAKE_ARGUMENTS \
				O=$(hget uboot output) \
				CROSS_COMPILE="$CROSS-" \
				$(hget uboot deploy-target) &&
			cp $(hget uboot deploy-target) ..
	fi
	if [ -x "$STAGING"/bin/fw_printenv ]; then
		deploy cp "$STAGING"/usr/bin/fw_printenv "$ROOTFS"/bin/
	fi
}

deploy-uboot() {
	deploy deploy-uboot-local
}
