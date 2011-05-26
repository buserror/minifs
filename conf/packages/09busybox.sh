

PACKAGES+=" libtool"
hset libtool url "http://ftp.gnu.org/gnu/libtool/libtool-2.4.tar.gz"
hset libtool destdir "$STAGING_TOOLS"
hset libtool prefix "/"

setup-libtool() {
	export LIBTOOL="$TARGET_FULL_ARCH"-libtool
}

configure-libtool() {
	configure-generic --program-prefix="$TARGET_FULL_ARCH"-
}
install-libtoot() {
	install-generic 
	ln -f -s "$TARGET_FULL_ARCH"-libtool "$STAGING_TOOLS"/bin/libtool
	ln -f -s "$TARGET_FULL_ARCH"-libtoolize "$STAGING_TOOLS"/bin/libtoolize
}

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
