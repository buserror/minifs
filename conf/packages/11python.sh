
PACKAGES+=" python2"
hset python2 url "https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tar.xz"
hset python2 depends "busybox"
hset python2 configscript "python-config"

configure-python2-local() {
	{ 	echo ac_cv_file__dev_ptmx=no;
		echo ac_cv_file__dev_ptc=no;
	} >config.site
	configure-generic-local \
		CONFIG_SITE=config.site \
		--disable-ipv6 \
		--enable-optimizations
}

configure-python2() {
	configure configure-python2-local
}

deploy-python2-local() {
	deploy_binaries
	ls -l $ROOTFS/usr/bin/py*
	# why these aren't picked by the auto-binary deploy is not known
	cp $STAGING_USR/bin/python2.* $ROOTFS/usr/bin/
}

deploy-python2() {
	deploy deploy-python2-local
}

PACKAGES+=" dbus-glib"
hset dbus-glib url "https://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.108.tar.gz"
hset dbus-glib depends "dbus glib"

patch-dbus-glib() {
	{
		sed -i -e 's/^SUBDIRS =.*/SUBDIRS = ./' dbus/Makefile.in
		sed -i -e 's/^SUBDIRS =.*/SUBDIRS = dbus/' Makefile.in
	}
}


PACKAGES+=" python-dbus"
hset python-dbus url "https://dbus.freedesktop.org/releases/dbus-python/dbus-python-1.2.4.tar.gz"
hset python-dbus depends "python2 dbus-glib"

