
# http://0pointer.de/lennart/projects/libdaemon/
PACKAGES+=" libdaemon"
hset libdaemon url "http://0pointer.de/lennart/projects/libdaemon/libdaemon-0.14.tar.gz"
hset libdaemon depends "libdaemon"

configure-libdaemon-local() {
	cat <<-END >config-fake.cache
	ac_cv_func_setpgrp_void=no
	END
	configure-generic-local \
		--cache=config-fake.cache
}
configure-libdaemon() {
	configure configure-libdaemon-local
}

# http://avahi.org/
PACKAGES+=" avahi"
hset avahi url "http://avahi.org/download/avahi-0.6.30.tar.gz"
hset avahi depends "libdaemon libexpat dbus"

configure-avahi-local() {
	configure-generic-local \
		--with-distro=none \
		--disable-glib \
		--disable-gtk \
		--disable-gtk3 \
		--disable-qt3 \
		--disable-qt4 \
		--disable-autoipd \
		--disable-gdbm \
		--disable-nsl \
		--disable-gobject \
		--disable-mono \
		--disable-python \
		--enable-compat-libdns_sd
}
configure-avahi() {
	configure configure-avahi-local
}

deploy-avahi-local() {
	deploy_binaries
	
	cat >>"$ROOTFS"/etc/passwd <<-END
	avahi:x:1000:1000:avahi:/home:/bin/false
	END
	cat >>"$ROOTFS"/etc/group <<-END
	avahi:x:1000:
	END
	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	echo "* Starting avahi..."
	avahi-daemon -D
	EOF
}

deploy-avahi() {
	deploy deploy-avahi-local
}
