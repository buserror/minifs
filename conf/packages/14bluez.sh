

PACKAGES+=" dbus"
hset dbus url "http://dbus.freedesktop.org/releases/dbus/dbus-1.4.0.tar.gz"
hset dbus depends "libexpat"

configure-dbus() {
	configure-generic \
		--without-x \
		--enable-xml-docs=no \
		--enable-doxygen-docs=no
}

deploy-dbus() {
	deploy deploy_binaries
}

PACKAGES+=" bluez"
hset bluez url "http://www.kernel.org/pub/linux/bluetooth/bluez-4.81.tar.gz"
hset bluez depends "dbus libiconv libgettext libglib"

configure-bluez() {
	configure-generic \
		--disable-alsa \
		--disable-audio \
		--disable-bccmd \
		--enable-configfiles \
		--disable-cups  \
		--disable-debug \
		--disable-dfutool \
		--enable-dund   \
		--disable-fortify \
		--disable-gstreamer \
		--disable-hid2hci \
		--enable-hidd \
		--enable-input \
		--disable-netlink \
		--enable-network \
		--enable-pand \
		--disable-pcmcia \
		--disable-pie \
		--enable-serial \
		--enable-service \
		--enable-tools \
		--disable-udevrules \
		--disable-usb
}

deploy-bluez() {
	deploy deploy_binaries
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
	deploy deploy_binaries
}


PACKAGES+=" cwiid"
hset cwiid url "http://abstrakraft.org/cwiid/downloads/cwiid-0.6.00.tgz"

configure-cwiid() {
	#export LDFLAGS='-lbluetooth -lrt -lpthread'
	autoreconf
	configure-generic \
		--without-python --disable-ldconfig
}

deploy-cwiid() {
	deploy deploy_binaries
#	deploy_staging_path "/etc/cwiid"
}

