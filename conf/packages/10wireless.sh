
PACKAGES+=" wireless-tools"
hset wireless-tools url "http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/wireless_tools.30.pre9.tar.gz"

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
hset libnl url "http://www.infradead.org/~tgr/libnl/files/libnl-1.0-pre6.tar.gz"

PACKAGES+=" libnl-tiny"
hset libnl-tiny url "svn!svn://svn.openwrt.org/openwrt/branches/backfire/package/libnl-tiny#libnl-tiny-svn.tar.bz2"
hset libnl-tiny svnopt "none" # no default -s
hset libnl-tiny dir "libnl-tiny/src"

compile-libnl-tiny() {
	compile $MAKE -j4 CC=$GCC CFLAGS="$TARGET_CPPFLAGS $TARGET_CFLAGS"
}
install-libnl-tiny-local() {
	rsync -av include/ "$STAGING_USR"/include/
	cp libnl-tiny.so "$STAGING_USR"/lib/
	ln -s libnl-tiny.so "$STAGING_USR"/lib/libnl.so
	ln -s libnl-tiny.so "$STAGING_USR"/lib/libnl-genl.so
}
install-libnl-tiny() {
	log_install install-libnl-tiny-local
}

# http://hostap.epitest.fi/wpa_supplicant/
PACKAGES+=" wpa-supplicant"
hset wpa-supplicant url "http://hostap.epitest.fi/releases/wpa_supplicant-0.7.3.tar.gz"
hset wpa-supplicant dir "wpa-supplicant/wpa_supplicant"
hset wpa-supplicant depends "libreadline libncurses libnl-tiny"

configure-wpa-supplicant-local() {
	if [ ! -f .config ]; then rm ._* ; fi
	if [ ! -f "$CONFIG"/config_wpa-supplicant.conf ]; then
		echo "### Target needs a config_wpa-supplicant.conf"
		echo "### Make one using the 'defconfig' file in the archive"
		exit 1
	fi
	cp "$CONFIG"/config_wpa-supplicant.conf \
		.config
}
configure-wpa-supplicant() {
	configure configure-wpa-supplicant-local
}

compile-wpa-supplicant() {
	compile $MAKE -j4 V=1 CC=$GCC \
		EXTRA_CFLAGS="$CPPFLAGS $TARGET_CFLAGS -D_GNU_SOURCE -DCONFIG_LIBNL20" \
		LIBS_c="-lreadline -lncurses"
}

install-wpa-supplicant() {
	# let the install tool fixes the paths for us
	install-generic \
		LIBDIR=/usr/lib \
		BINDIR=/usr/bin
}

# file donwloaded for RALink cards: 
# RT2860_Firmware_V26.zip
# RT2870_Firmware_V22.zip
deploy-wpa-supplicant() {
	# let the install tool fixes the paths for us
	deploy cp "$STAGING_USR"/bin/wpa* "$ROOTFS"/usr/bin/
	mkdir -p "$ROOTFS"/lib/firmware/
	cp "$PATCHES"/wpa-supplicant/firmware/* "$ROOTFS"/lib/firmware/
	touch "$ROOTFS"/etc/wpa.conf
}
