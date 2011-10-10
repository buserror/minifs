
PACKAGES="$PACKAGES busybox"
hset busybox url "http://busybox.net/downloads/busybox-$(hget busybox version).tar.bz2"
hset busybox depends "crosstools libtool"

configure-busybox() {
	if [ -f "$CONFIG"/config_busybox.conf ]; then
		configure cp -a  "$CONFIG"/config_busybox.conf .config
	else
		configure $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" defconfig
		COMMAND="busybox_menuconfig"
	fi
	if [ "$COMMAND_PACKAGE" = "busybox" ] ; then
		$MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" $COMMAND_TARGET

		echo #### busybox config done, copying it back
		cp .config "$CONFIG"/config_busybox.conf
		rm ._*
		exit 0
	fi
}

compile-busybox() {
	compile $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" -j8
}

install-busybox() {
	log_install echo Done
}

deploy-busybox() {
	deploy $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" install
}
