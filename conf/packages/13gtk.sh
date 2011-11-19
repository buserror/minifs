
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
hset libffi url "ftp://sourceware.org/pub/libffi/libffi-3.0.9.tar.gz"

# More recent version of glib fails to conf because of lack of glib-compile-schemas
PACKAGES+=" libglib"
#hset libglib url "http://ftp.gnome.org/pub/gnome/sources/glib/2.24/glib-2.24.1.tar.bz2"
#hset libglib url "http://ftp.gnome.org/pub/gnome/sources/glib/2.28/glib-2.28.7.tar.bz2"
hset libglib url "http://ftp.gnome.org/pub/gnome/sources/glib/2.29/glib-2.29.18.tar.bz2"
#hset libglib prefix "$STAGING_USR"
# this is needed for uclibc not NOT otherwise!
hset libglib depends "libffi"

hostcheck-libglib() {
	local genm=$(which glib-genmarshal)
	if [ ! -x "$genm" ]; then
		echo "### Stupid libglib needs part of itself () to compile."
		echo "    please install glib-genmarshal (libglib2.0-dev on debian)"
		HOSTCHECK_FAILED=1
	fi
}

setup-libglib() {
	# dont deploy python garbage
	local exc=$(hget sharedlibs exclude)
	hset sharedlibs exclude "$exc:gdbus-2.0"
}

configure-libglib-local() {
	printf "glib_cv_stack_grows=no
ac_cv_func_posix_getpwuid_r=yes
ac_cv_func_posix_getgrgid_r=yes
glib_cv_uscore=no
ac_cv_func_qsort_r=no
" >fake_glib_cache.conf
	# yuck yuck yuck. fixes ARM thumb build
	sed -i -e 's:swp %0, %1, \[%2\]:nop:g' glib/gatomic.c
	rm -f configure
	save=$CFLAGS
	CFLAGS+=" -DDISABLE_IPV6"
	export CFLAGS
	export LDFLAGS="$LDFLAGS_RLINK -Wl,-rpath -Wl,$BUILD/libglib/gthread/.libs -Wl,-rpath -Wl,$BUILD/libglib/gmodule/.libs"
	export NOCONFIGURE=1
	configure-generic-local \
		--cache=fake_glib_cache.conf \
		--with-pcre=internal || { echo FAILED ; exit 1; }
	export LDFLAGS="$LDFLAGS_BASE"
	export CFLAGS=$save
	unset NOCONFIGURE
}

configure-libglib() {
	configure configure-libglib-local
}

PACKAGES+=" libglibnet"
#hset libglibnet url "http://ftp.gnome.org/pub/gnome/sources/glib-networking/2.28/glib-networking-2.28.7.tar.bz2"
hset libglibnet url "http://ftp.gnome.org/pub/gnome/sources/glib-networking/2.29/glib-networking-2.29.18.tar.bz2"
hset libglibnet depends "gnutls libglib"
hset libglibnet destdir "none" # let out own "install" fix borken autocrap

setup-libglibnet() {
	ROOTFS_KEEPERS+="libgnutls.so:"
}

configure-libglibnet-local() {
	configure-generic-local \
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
hset libglibjson url "http://ftp.gnome.org/pub/GNOME/sources/json-glib/0.13/json-glib-0.13.4.tar.bz2"
hset libglibjson depends "libglib"

PACKAGES+=" libsoup"
#hset libsoup url "http://ftp.gnome.org/pub/gnome/sources/libsoup/2.33/libsoup-2.33.6.tar.bz2"
hset libsoup url "http://ftp.gnome.org/pub/gnome/sources/libsoup/2.35/libsoup-2.35.5.tar.bz2"
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
#	cp -r "$STAGING_USR"/etc/pango/* \
#		"$ROOTFS"/etc/pango/
}

deploy-libpango() {
	deploy deploy-libpango-local
}

PACKAGES+=" libatk"
#hset libatk url "http://ftp.gnome.org/pub/gnome/sources/atk/1.33/atk-1.33.6.tar.bz2"
hset libatk url "http://ftp.gnome.org/pub/gnome/sources/atk/1.33/atk-1.33.6.tar.bz2"

configure-libatk() {
	# 1.33.6: prevents glib faling because of atk using G_CONST_RETURN
	sed -i -e '/G_DISABLE_DEPRECATED/d' atk/Makefile.am
	sed -i -e '/G_DISABLE_DEPRECATED/d' tests/Makefile.am
	rm -f configure
	configure-generic
}
PACKAGES+=" libgdkpixbuf"
hset libgdkpixbuf url "http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.23/gdk-pixbuf-2.23.1.tar.bz2"

configure-libgdkpixbuf() {
	printf "gio_can_sniff=yes" >fake_gtk_cache.conf
	configure-generic \
		--cache=fake_gtk_cache.conf \
		--disable-glibtest \
		--without-libtiff	
}

# this is included in GTK
#PACKAGES+=" libgail"
#hset libgail url "http://ftp.acc.umu.se/pub/gnome/sources/gail/1.22/gail-1.22.3.tar.bz2"

PACKAGES+=" libgtk"
#hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.18/gtk+-2.18.7.tar.gz#libgtk-2.18.tar.gz"
hset libgtk url "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.3.tar.gz#libgtk-2.24.tar.gz"
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
