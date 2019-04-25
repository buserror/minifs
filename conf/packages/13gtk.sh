
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

PACKAGES+=" libffi"
hset libffi url "ftp://sourceware.org/pub/libffi/libffi-3.0.13.tar.gz"

# More recent version of glib fails to conf because of lack of glib-compile-schemas
PACKAGES+=" libglib"
#hset libglib url "http://ftp.gnome.org/pub/gnome/sources/glib/2.39/glib-2.39.1.tar.xz"
hset libglib url "http://ftp.gnome.org/pub/gnome/sources/glib/2.47/glib-2.47.4.tar.xz"

#hset libglib prefix "$STAGING_USR"
# this is needed for uclibc not NOT otherwise!
hset libglib depends "libffi libiconv libgettext zlib"

hostcheck-libglib() {
	hostcheck_commands glib-genmarshal glib-compile-schemas || {
		echo "### Stupid libglib needs part of itself () to compile."
		echo "    please install libglib2.0-dev and/or gtk-doc"
		exit 1
	}
}

setup-libglib() {
	# dont deploy python garbage
	local exc=$(hget sharedlibs exclude)
	hset sharedlibs exclude "$exc:gdbus-2.0"
}

configure-libglib-local() {
	local uclibc=$(minifs_locate_config_path config_uclibc.conf)
	if [ -f "$uclibc" ]; then
		local has_locale=$(grep 'UCLIBC_HAS_LOCALE=y' $uclibc)
		local has_wchar=$(grep 'UCLIBC_HAS_WCHAR=y' $uclibc)
		echo has_locale=$has_locale
		echo has_wchar=$has_wchar
	fi
	printf "glib_cv_stack_grows=no
ac_cv_func_posix_getpwuid_r=yes
ac_cv_func_posix_getgrgid_r=yes
glib_cv_uscore=no
ac_cv_func_qsort_r=no
" >fake_glib_cache.conf
	# yuck yuck yuck. fixes ARM thumb build
	sed -i -e 's:swp %0, %1, \[%2\]:nop:g' glib/gatomic.c
#	sed -i -e 's/^PKG_PROG_PKG_CONFIG/# PKG_PROG_PKG_CONFIG/' configure.ac
#	rm -f configure
	save=$CFLAGS
	CFLAGS+=" -DDISABLE_IPV6 -DDISABLE_DN_SKIPNAME"
	export CFLAGS
	export LDFLAGS="$LDFLAGS_RLINK -Wl,-rpath -Wl,$BUILD/libglib/gthread/.libs -Wl,-rpath -Wl,$BUILD/libglib/gmodule/.libs"
	export NOCONFIGURE=1
	if [ "$CONFIG_UCLIBC" != "" ]; then
		iconv=gnu
	else
		iconv=no
	fi
	configure-generic-local \
		--cache=fake_glib_cache.conf \
		--with-libiconv=$iconv \
		--with-pcre=internal || { echo FAILED ; return 1; }
	export LDFLAGS="$LDFLAGS_BASE"
	export CFLAGS=$save
	unset NOCONFIGURE
}

configure-libglib() {
	configure configure-libglib-local
}

PACKAGES+=" libglibnet"
#hset libglibnet url "http://ftp.gnome.org/pub/gnome/sources/glib-networking/2.39/glib-networking-2.39.1.tar.xz"
hset libglibnet url "http://ftp.gnome.org/pub/gnome/sources/glib-networking/2.47/glib-networking-2.47.1.tar.xz"
hset libglibnet depends "libglib"
hset libglibnet destdir "none" # let out own "install" fix borken autocrap

configure-libglibnet-local() {
	configure-generic-local \
		--without-gnutls \
		--disable-glibtest \
		--with-libgcrypt-prefix="$STAGING_USR" \
		--with-ca-certificates=/etc/ca-certificates.crt \
		DESTDIR="$STAGING_USR"
}

configure-libglibnet() {
	configure configure-libglibnet-local
}

PACKAGES+=" libglibjson"
#hset libglibjson url "http://ftp.gnome.org/pub/GNOME/sources/json-glib/0.12/json-glib-0.12.4.tar.bz2"
#hset libglibjson url "http://ftp.gnome.org/pub/GNOME/sources/json-glib/0.13/json-glib-0.13.4.tar.bz2"
#hset libglibjson url "http://ftp.gnome.org/pub/GNOME/sources/json-glib/0.15/json-glib-0.15.2.tar.bz2"
hset libglibjson url "http://ftp.gnome.org/pub/GNOME/sources/json-glib/1.0/json-glib-1.0.4.tar.bz2"
hset libglibjson depends "libglib"

PACKAGES+=" libsoup"
#hset libsoup url "http://ftp.gnome.org/pub/gnome/sources/libsoup/2.44/libsoup-2.44.2.tar.xz"
#hset libsoup url "http://ftp.acc.umu.se/pub/gnome/sources/libsoup/2.50/libsoup-2.50.0.tar.xz"
#hset libsoup url "http://ftp.acc.umu.se/pub/gnome/sources/libsoup/2.51/libsoup-2.51.3.tar.xz"
hset libsoup url "http://ftp.acc.umu.se/pub/gnome/sources/libsoup/2.53/libsoup-2.53.2.tar.xz"
hset libsoup depends "libglibnet libxml2"

configure-libsoup-local() {
	rm -f configure # since patches 'fix' the config, remove this
	configure-generic-local \
		--without-gnome \
		--without-sqlite \
		--enable-vala=no \
		--disable-glibtest
}
configure-libsoup() {
	configure configure-libsoup-local
}

# http://www.cairographics.org/
PACKAGES+=" libcairo"
#hset libcairo url "http://www.cairographics.org/releases/cairo-1.12.16.tar.xz"
hset libcairo url "http://www.cairographics.org/releases/cairo-1.14.6.tar.xz"
hset libcairo depends "libfreetype libpng libglib libpixman"

configure-libcairo() {
	export LDFLAGS="$LDFLAGS_RLINK"
	local extras=""
	if [ "$TARGET_ARCH" == "arm" ]; then
		extras+=" --disable-some-floating-point "
	fi
	if [[ $TARGET_X11 ]]; then
		extras+=" --enable-xlib \
		--enable-xlib-xcb=yes \
		--enable-xlib-xrender=yes \
		--with-x "
		LDFLAGS+=" -lxcb"
	else
		extras+=" --enable-xlib=no \
		--enable-xlib-xrender=no \
		--without-x "
	fi
	extras+=" --enable-directfb=no"
	configure-generic $extras
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libharfbuzz"
#hset libharfbuzz url "http://cgit.freedesktop.org/harfbuzz/snapshot/harfbuzz-0.9.14.tar.gz"
hset libharfbuzz url "http://cgit.freedesktop.org/harfbuzz/snapshot/harfbuzz-1.1.2.tar.gz"
hset libharfbuzz depends "libfontconfig libcairo"
hset libharfbuzz optional "libicu"

configure-libharfbuzz-local() {
	# Add the extra header. it's needed by libwebkit
	sed -i -e 's/hb-unicode.h \\/hb-unicode.h hb-icu.h \\/g' src/Makefile.am
	configure-generic \
		ac_cv_path_icu_config=no
}
configure-libharfbuzz() {
	configure configure-libharfbuzz-local
}

PACKAGES+=" libpango"
#hset libpango url "http://ftp.gnome.org/pub/gnome/sources/pango/1.36/pango-1.36.1.tar.xz"
hset libpango url "http://ftp.gnome.org/pub/gnome/sources/pango/1.39/pango-1.39.0.tar.xz"
hset libpango depends "libglib libcairo libharfbuzz"
hset libpango optional "libpng"

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
#	cp 	"$STAGING_USR"/bin/pango-querymodules \
#		"$ROOTFS"/bin/
}

deploy-libpango() {
	deploy deploy-libpango-local
}

PACKAGES+=" libatk"
#hset libatk url "http://ftp.acc.umu.se/pub/gnome/sources/atk/2.11/atk-2.11.3.tar.xz"
hset libatk url "http://ftp.acc.umu.se/pub/gnome/sources/atk/2.18/atk-2.18.0.tar.xz"

configure-libatk() {
	# 1.33.6: prevents glib faling because of atk using G_CONST_RETURN
	sed -i -e '/G_DISABLE_DEPRECATED/d' atk/Makefile.am
	sed -i -e '/G_DISABLE_DEPRECATED/d' tests/Makefile.am
	rm -f configure
	configure-generic
}
PACKAGES+=" libgdkpixbuf"
#hset libgdkpixbuf url "http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.30/gdk-pixbuf-2.30.1.tar.xz"
hset libgdkpixbuf url "http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.33/gdk-pixbuf-2.33.2.tar.xz"

configure-libgdkpixbuf() {
	printf "gio_can_sniff=yes" >fake_gtk_cache.conf
	configure-generic \
		--cache=fake_gtk_cache.conf \
		--disable-glibtest \
		--without-libtiff
}

deploy-libgdkpixbuf() {
	deploy deploy_binaries
}

# this is included in GTK
#PACKAGES+=" libgail"
#hset libgail url "http://ftp.acc.umu.se/pub/gnome/sources/gail/1.22/gail-1.22.3.tar.bz2"

PACKAGES+=" libgtk"
#hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.18/gtk+-2.18.7.tar.gz#libgtk-2.18.tar.gz"
#hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.3.tar.gz#libgtk-2.24.tar.gz"
#hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.14.tar.xz#libgtk-2.24.tar.xz"
#hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.22.tar.xz"
hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.29.tar.xz"
hset libgtk depends "libpango libatk libgtkhicolor libgdkpixbuf"

hostcheck-libgtk() {
	local cmd=$(which gtk-update-icon-cache)
	if [ ! -x "$cmd" ]; then
		echo "### ERROR $PACKAGE needs gtk-update-icon-cache"
		echo "    It's in libgtk2.0-bin on debian"
		HOSTCHECK_FAILED=1
	fi
}

configure-libgtk-local() {
	set -x
	if [ ! -d "$CROSS_BASE/$TARGET_FULL_ARCH/lib" ];then
		# stupid gtk needs that, somehow
		pushd "$CROSS_BASE/$TARGET_FULL_ARCH" >/dev/null
		ln -s sysroot/lib lib
		popd  >/dev/null
	fi
	if [ "$TARGET_ARCH" = "x86_64" ]; then
		if [ ! -d "$CROSS_BASE/$TARGET_FULL_ARCH/lib64" ];then
			# stupid gtk needs that, somehow. pile of garbage
			pushd "$CROSS_BASE/$TARGET_FULL_ARCH" >/dev/null
			ln -s sysroot/lib lib64
			popd  >/dev/null
		fi
	fi
	# remove the demos
#	sed -i '/^demos\//d ; /^tests\//d' configure.in
	sed -i 's|demos||g ; s|tests||g' Makefile.am
	rm -f configure
	printf "gio_can_sniff=yes" >fake_gtk_cache.conf
	export LDFLAGS="$LDFLAGS_RLINK"
	if [[ $TARGET_X11 ]]; then
		extras="--with-x --with-gdktarget=x11"
		export LDFLAGS="$LDFLAGS -lxcb"
	else
		extras="--without-x --with-gdktarget=directfb"
	fi
	configure-generic-local \
		--cache=fake_gtk_cache.conf \
		--disable-glibtest \
		--disable-cups \
		--disable-papi \
		--disable-gtk-doc-html \
		--with-libiconv=no \
		$extras
	export LDFLAGS="$LDFLAGS_BASE"
}

configure-libgtk() {
	configure configure-libgtk-local
}

deploy-libgtk-local() {
#	cp -r "$STAGING_USR"/etc/gtk-2.0 "$ROOTFS"/etc
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
#hset libgtkhicolor url "http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.12.tar.gz"
hset libgtkhicolor url "http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.15.tar.xz"

PACKAGES+=" libcroco"
#hset libcroco url "ftp://ftp.gnome.org/pub/GNOME/sources/libcroco/0.6/libcroco-0.6.2.tar.bz2"
#hset libcroco url "ftp://ftp.gnome.org/pub/GNOME/sources/libcroco/0.6/libcroco-0.6.8.tar.bz2"
hset libcroco url "ftp://ftp.gnome.org/pub/GNOME/sources/libcroco/0.6/libcroco-0.6.9.tar.bz2"

PACKAGES+=" librsvg"
#hset librsvg url "http://ftp.gnome.org/pub/gnome/sources/librsvg/2.32/librsvg-2.32.1.tar.bz2"
#hset librsvg url "http://ftp.gnome.org/pub/gnome/sources/librsvg/2.36/librsvg-2.36.4.tar.bz2"
#hset librsvg url "http://ftp.gnome.org/pub/gnome/sources/librsvg/2.40/librsvg-2.40.1.tar.bz2"
hset librsvg url "http://ftp.gnome.org/pub/gnome/sources/librsvg/2.40/librsvg-2.40.13.tar.bz2"
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
