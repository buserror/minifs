

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

