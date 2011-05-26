
PACKAGES+=" libdirectfb"
hset libdirectfb url "http://www.directfb.org/downloads/Core/DirectFB-1.4/DirectFB-1.4.3.tar.gz"
hset libdirectfb depends "libts"

configure-libdirectfb() {
	configure-generic \
		--disable-debug-support \
		--disable-video4linux \
		--disable-video4linux2 \
		--with-gfxdrivers=none \
		--with-inputdrivers=tslib,linuxinput \
		--without-tests
}

deploy-libdirectfb() {
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/directfb-1.4-0-pure:"
	deploy cp "$STAGING_USR"/bin/dfb* "$ROOTFS/usr/bin"
}

# More recent version of glib fails to conf because of lack of glib-compile-schemas
PACKAGES+=" libglib"
#hset libglib url "http://ftp.gnome.org/pub/gnome/sources/glib/2.24/glib-2.24.1.tar.bz2"
hset libglib url "http://ftp.gnome.org/pub/gnome/sources/glib/2.28/glib-2.28.3.tar.bz2"
#hset libglib prefix "$STAGING_USR"
# this is needed for uclibc not NOT otherwise!
# hset depends libglib "libiconv"

configure-libglib() {
	printf "glib_cv_stack_grows=no
ac_cv_func_posix_getpwuid_r=yes
ac_cv_func_posix_getgrgid_r=yes
glib_cv_uscore=no
" >fake_glib_cache.conf
	# yuck yuck yuck. fixes ARM thumb build
	sed -i -e 's:swp %0, %1, \[%2\]:nop:g' glib/gatomic.c
	rm -f configure
	save=$CFLAGS
	CFLAGS+=" -DDISABLE_IPV6"
	export CFLAGS
	export LDFLAGS="$LDFLAGS_RLINK -Wl,-rpath -Wl,$BUILD/libglib/gthread/.libs -Wl,-rpath -Wl,$BUILD/libglib/gmodule/.libs"
	configure-generic \
		--cache=fake_glib_cache.conf \
		--with-pcre=internal
	export LDFLAGS="$LDFLAGS_BASE"
	export CFLAGS=$save
}

PACKAGES+=" libglibnet"
hset libglibnet url "http://ftp.gnome.org/pub/gnome/sources/glib-networking/2.28/glib-networking-2.28.4.tar.bz2"
hset libglibnet destdir "gnutls"

setup-libglibnet() {
	ROOTFS_KEEPERS+="libgnutls.so:"
}

configure-libglibnet() {
	configure-generic \
		--without-gnome \
		--disable-glibtest \
		--with-libgcrypt-prefix="$STAGING_USR" \
		--with-ca-certificates=/etc/ca-certificates.crt
}

PACKAGES+=" libsoup"
hset libsoup url "http://ftp.gnome.org/pub/gnome/sources/libsoup/2.33/libsoup-2.33.6.tar.bz2"
hset libsoup depends "libglibnet"

configure-libsoup() {
	configure-generic \
		--without-gnome \
		--disable-glibtest
}

# http://www.cairographics.org/
PACKAGES+=" libcairo"
#hset libcairo url "http://www.cairographics.org/releases/cairo-1.8.10.tar.gz"
#hset libcairo url "http://www.cairographics.org/releases/cairo-1.9.6.tar.gz"
hset libcairo url "http://www.cairographics.org/releases/cairo-1.10.2.tar.gz"
hset libcairo depends "libfreetype libpng libglib libpixman"

configure-libcairo() {
	local extras=""
	if [ "$TARGET_ARCH" == "arm" ]; then
		extras+=" --disable-some-floating-point "
	fi
	if [[ $TARGET_X11 ]]; then
		extras+=" --enable-xlib=yes \
		--enable-xlib-xrender=yes \
		--with-x "
	else
		extras+=" --enable-xlib=no \
		--enable-xlib-xrender=no \
		--without-x "
	fi
	extras+=" --enable-directfb=no"
	configure-generic $extras
}

PACKAGES+=" libpango"
hset libpango url "http://ftp.gnome.org/pub/gnome/sources/pango/1.28/pango-1.28.3.tar.bz2"
hset libpango depends "libglib libcairo"

configure-libpango() {
	export LDFLAGS="$LDFLAGS_RLINK"
	local extras=""
	if [[ ! $TARGET_X11 ]]; then
		extras="--without-x"
	else
		export LDFLAGS+=" -lxcb"
	#	extras="--x-libraries=$STAGING_USR/lib \
	#		--x-includes=$STAGING_USR/include"
	fi
	configure-generic "$extras" 
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-libpango-local() {
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/pango:"
	mkdir -p "$ROOTFS"/etc/	# in case it was there already
	cp 	"$STAGING_USR"/bin/pango-querymodules \
		"$ROOTFS"/bin/
	cp -r "$STAGING_USR"/etc/pango/* \
		"$ROOTFS"/etc/pango/
}

deploy-libpango() {
	deploy deploy-libpango-local
}

PACKAGES+=" libatk"
hset libatk url "http://ftp.gnome.org/pub/gnome/sources/atk/1.33/atk-1.33.6.tar.bz2"

PACKAGES+=" libgdkpixbuf"
hset libgdkpixbuf url "http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.23/gdk-pixbuf-2.23.1.tar.bz2"

configure-libgdkpixbuf() {
	printf "gio_can_sniff=yes" >fake_gtk_cache.conf
	configure-generic \
		--cache=fake_gtk_cache.conf \
		--disable-glibtest \
		--without-libtiff	
}

PACKAGES+=" libgtk"
#hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.18/gtk+-2.18.7.tar.gz#libgtk-2.18.tar.gz"
hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.3.tar.gz#libgtk-2.24.tar.gz"
hset libgtk depends "libpango libatk libgtkhicolor libgdkpixbuf"

configure-libgtk() {
	if [ ! -d "$CROSS_BASE/$TARGET_FULL_ARCH/lib" ];then 
		# stupid gtk needs that, somehow
		pushd "$CROSS_BASE/$TARGET_FULL_ARCH" >/dev/null
		ln -s sysroot/lib lib
		popd  >/dev/null
	fi

	printf "gio_can_sniff=yes" >fake_gtk_cache.conf
	export LDFLAGS="$LDFLAGS_RLINK"
	if [[ $TARGET_X11 ]]; then
		extras="--with-x --with-gdktarget=x11"
		export LDFLAGS="$LDFLAGS -lxcb"
	else
		extras="--without-x --with-gdktarget=directfb"
	fi
	configure-generic \
		--cache=fake_gtk_cache.conf \
		--disable-glibtest \
		--disable-cups \
		--disable-papi \
		$extras	
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-libgtk-local() {
	cp -r "$STAGING_USR"/etc/gtk-2.0 "$ROOTFS"/etc
	rsync -av \
		"$STAGING_USR/share/icons" \
		"$STAGING_USR/share/themes" \
		"$ROOTFS/usr/share/"
}

deploy-libgtk() {
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/gtk-2.0:"
	deploy  deploy-libgtk-local
}

PACKAGES+=" libgtkhicolor"
hset libgtkhicolor url "http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.12.tar.gz"

PACKAGES+=" libcroco"
hset libcroco url "ftp://ftp.gnome.org/pub/GNOME/sources/libcroco/0.6/libcroco-0.6.2.tar.bz2"

PACKAGES+=" librsvg"
hset librsvg url "http://ftp.gnome.org/pub/gnome/sources/librsvg/2.32/librsvg-2.32.1.tar.bz2"
hset librsvg depends "libcroco libxml2 libgtk"

configure-librsvg() {
	export LDFLAGS="$LDFLAGS_RLINK"
	if [[ $TARGET_X11 ]]; then
		extras="--with-x"
	else
		extras="--without-x"
	fi
	#	--without-croco 
	configure-generic \
		--with-defaults \
		--without-svgz \
		--disable-mozilla-plugin \
		--disable-pixbuf-loader \
		--disable-gtk-theme \
		$extras 
	export LDFLAGS="$LDFLAGS_BASE"
}
