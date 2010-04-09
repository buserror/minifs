
PACKAGES+=" wireless-tools"
hset url wireless-tools "http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/wireless_tools.29.tar.gz"

compile-wireless-tools() {
	compile $MAKE \
		CC=$GCC \
		CFLAGS="$TARGET_CFLAGS" \
		RANLIB=${CROSS}-ranlib \
		BUILD_WE_ESSENTIAL=y \
		PREFIX=/usr
}

install-wireless-tools() {
	log_install $MAKE \
		BUILD_WE_ESSENTIAL=y \
		PREFIX="$STAGING_USR" \
			install
}

deploy-wireless-tools() {
	deploy cp "$STAGING_USR"/sbin/iw* \
		"$STAGING_USR"/sbin/ifrename \
		"$ROOTFS"/sbin/
}

PACKAGES+=" libnl"
hset url libnl "http://www.infradead.org/~tgr/libnl/files/libnl-1.0-pre6.tar.gz"

PACKAGES+=" libnl-tiny"
hset url libnl-tiny "svn!svn://svn.openwrt.org/openwrt/branches/backfire/package/libnl-tiny#libnl-tiny-svn.tar.bz2"
hset svnopt libnl-tiny "none" # no default -s
hset dir libnl-tiny "libnl-tiny/src"

compile-libnl-tiny() {
	compile $MAKE -j4 CC=$GCC CFLAGS="$TARGET_CPPFLAGS $TARGET_CFLAGS"
}
install-libnl-tiny-local() {
	rsync -av include/ "$STAGING_USR"/include/
	cp libnl-tiny.so "$STAGING_USR"/lib/
	ln -s libnl-tiny.so "$STAGING_USR"/lib/libnl.so
}
install-libnl-tiny() {
	log_install install-libnl-tiny-local
}

PACKAGES+=" wpa-supplicant"
hset url wpa-supplicant "http://hostap.epitest.fi/releases/wpa_supplicant-0.6.10.tar.gz"
hset dir wpa-supplicant "wpa-supplicant/wpa_supplicant"
hset depends wpa-supplicant "libreadline libncurses libnl-tiny"

configure-wpa-supplicant() {
	if [ ! -f .config ]; then rm ._* ; fi
	if [ ! -f "$CONFIG"/config_wpa-supplicant.conf ]; then
		echo "### Target needs a config_wpa-supplicant.conf"
		echo "### Make one using the 'defconfig' file in the archive"
		exit 1
	fi
	configure cp "$CONFIG"/config_wpa-supplicant.conf \
		.config
}

compile-wpa-supplicant() {
	compile $MAKE -j4 V=1 CC=$GCC EXTRA_CFLAGS="$CPPFLAGS $TARGET_CFLAGS -D_GNU_SOURCE"
}

