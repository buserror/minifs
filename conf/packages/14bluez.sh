

PACKAGES+=" dbus"
hset dbus url "http://dbus.freedesktop.org/releases/dbus/dbus-1.11.6.tar.gz"
hset dbus depends "libexpat"
hset dbus optional "python2"

configure-dbus() {
	configure-generic \
		--without-x \
		--enable-xml-docs=no \
		--enable-doxygen-docs=no \
		--localstatedir=/tmp
}

deploy-dbus-local() {
	deploy_binaries
	rsync -a "$STAGING_USR"/share/dbus-1 "$ROOTFS"/usr/share/

	cat >>"$ROOTFS"/etc/passwd <<-END
	messagebus:x:1002:1002:avahi:/home:/bin/false
	END
	cat >>"$ROOTFS"/etc/group <<-END
	messagebus:x:1002:
	END
	cat >>"$ROOTFS"/etc/network-up.sh <<-EOF
	echo "* Starting dbus bloatware..."
	mkdir -p /tmp/run/dbus
	dbus-daemon --system &
	EOF
}

deploy-dbus() {
	deploy deploy-dbus-local
}

PACKAGES+=" libical"
hset libical url "https://github.com/libical/libical/releases/download/v2.0.0/libical-2.0.0.tar.gz"

configure-libical() {
	configure cmake -DCMAKE_INSTALL_PREFIX=/usr .
}

PACKAGES+=" bluez4"
hset bluez4 url "http://www.kernel.org/pub/linux/bluetooth/bluez-4.81.tar.gz"
hset bluez4 depends "dbus libiconv libgettext libglib libical libreadline"
hset bluez4 optional "python-dbus"

setup-bluez4() {
	if [ -f $CONFIG/config_uclibc.conf ]; then
		local conf=$(grep '^UCLIBC_HAS_WORDEXP' $CONFIG/config_uclibc.conf)
		if [ "$conf" == "" ]; then
			echo "** ERROR package $PACKAGE requires a uCLibc with WORDEXP support"
			exit 1
		fi
	fi
}

configure-bluez4() {
	export LIBS="-lncurses"
	export LDFLAGS="$LDFLAGS_BASE"
	configure-generic \
		--disable-cups  \
		--disable-debug \
		--disable-pie \
		--enable-tools \
		--enable-alsa
	export LIBS=""
}
deploy-bluez4-local() {
	deploy_binaries
	mkdir -p $ROOTFS/etc/bluetooth
	cp audio/audio.conf $ROOTFS/etc/bluetooth/
}

deploy-bluez4() {
	deploy deploy-bluez4-local
}

PACKAGES+=" bluez"
#hset bluez url "http://www.kernel.org/pub/linux/bluetooth/bluez-4.81.tar.gz"
hset bluez url "http://www.kernel.org/pub/linux/bluetooth/bluez-5.43.tar.gz"
hset bluez depends "dbus libiconv libgettext libglib libical libreadline"

setup-bluez() {
	if [ -f $CONFIG/config_uclibc.conf ]; then
		local conf=$(grep '^UCLIBC_HAS_WORDEXP' $CONFIG/config_uclibc.conf)
		if [ "$conf" == "" ]; then
			echo "** ERROR package $PACKAGE requires a uCLibc with WORDEXP support"
			exit 1
		fi
	fi
}

configure-bluez() {
	export LIBS="-lncurses"
	export LDFLAGS="$LDFLAGS_BASE"
	configure-generic \
		--disable-cups  \
		--disable-debug \
		--disable-pie \
		--enable-tools \
		--disable-udev \
		--disable-systemd
	export LIBS=""
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
	rm -f $STAGING/etc/dbus-1/system.d 
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

