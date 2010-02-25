
PACKAGES="$PACKAGES busybox"
hset url busybox	"http://busybox.net/downloads/busybox-${VERSION_busybox}.tar.bz2"

configure-busybox() {
	if [ -f "$CONFIG"/config_busybox.conf ]; then
		configure cp -a  "$CONFIG"/config_busybox.conf .config
	else
		configure $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" defconfig
		COMMAND="busybox_menuconfig"
	fi
	if [ "$COMMAND" = "busybox_menuconfig" ]; then
		$MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" menuconfig

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
