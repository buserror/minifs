

PACKAGES+=" dbus"
hset dbus url "http://dbus.freedesktop.org/releases/dbus/dbus-1.4.0.tar.gz"
hset dbus depends "libexpat"

configure-dbus() {
	configure-generic \
		--without-x \
		--enable-xml-docs=no \
		--enable-doxygen-docs=no
}

PACKAGES+=" bluez"
hset bluez url "http://www.kernel.org/pub/linux/bluetooth/bluez-4.81.tar.gz"
hset bluez depends "dbus libiconv libgettext libglib"

deploy-bluez() {
	deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
}

PACKAGES+=" btscanner"
hset btscanner url "http://www.pentest.co.uk/src/btscanner-2.1.tar.bz2"
hset btscanner depends "bluez libxml2 libncurses"

configure-btscanner() {
	export LDFLAGS="$LDFLAGS_RLINK -lz"
	export ac_cv_func_malloc_0_nonnull=yes
	rm -f configure
	sed -i -e 's|-Wimplicit-function-dec||g' configure.in
	configure-generic 
	export LDFLAGS="$LDFLAGS_BASE"
	unset ac_cv_func_malloc_0_nonnull
}

deploy-btscanner() {
	deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
}
