
if [[ $TARGET_DIRECTFB ]]; then
	PACKAGES+=" libdirectfb"
	DIRECTFB_PACKAGE=libdirectfb
fi
hset url libdirectfb "http://www.directfb.org/downloads/Core/DirectFB-1.4/DirectFB-1.4.3.tar.gz"

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
	deploy cp "$STAGING_USR"/bin/dfb* "$ROOTFS/usr/bin"
}

PACKAGES+=" libcairo"
hset url libcairo "http://www.cairographics.org/releases/cairo-1.8.10.tar.gz"

configure-libcairo() {
	local extras=""
	if [ "$TARGET_ARCH" == "arm" ]; then
		extras+=" --disable-some-floating-point"
	fi
	if [[ $TARGET_X11 ]]; then
		configure-generic \
		--enable-xlib=yes \
		--enable-xlib-xrender=yes \
		--enable-directfb=no \
		--with-x $extras
	else
		configure-generic \
		--enable-xlib=no \
		--enable-xlib-xrender=no \
		--enable-directfb=yes \
		--without-x $extras
	fi
}

PACKAGES+=" libglib"
hset url libglib "http://ftp.gnome.org/pub/gnome/sources/glib/2.23/glib-2.23.4.tar.bz2"
hset prefix libglib "$STAGING_USR"
hset destdir libglib "none"
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
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic \
		--cache=fake_glib_cache.conf 
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libpango"
hset url libpango "http://ftp.gnome.org/pub/gnome/sources/pango/1.26/pango-1.26.2.tar.bz2"
hset depends libpango "libglib libcairo"

configure-libpango() {
	if [[ ! $TARGET_X11 ]]; then
		extras="--without-x"
	fi
	export LDFLAGS="$LDFLAGS_RLINK -lxcb"
	configure-generic "$extras" \
		--x-libraries=$STAGING_USR/lib \
		--x-includes=$STAGING_USR/include 		
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-libpango() {
	cp 	"$STAGING_USR"/bin/pango* \
		"$ROOTFS"/bin/
	mkdir -p "$ROOTFS"/etc/	# in case it was there already
	cp -r "$STAGING_USR"/etc/pango/* \
		"$ROOTFS"/etc/pango/
}

PACKAGES+=" libatk"
hset url libatk "http://ftp.gnome.org/pub/gnome/sources/atk/1.28/atk-1.28.0.tar.bz2"

PACKAGES+=" libgtk"
hset url libgtk "http://ftp.gnome.org/pub/gnome/sources/gtk+/2.18/gtk+-2.18.7.tar.gz#libgtk-2.18.tar.gz"
hset depends libgtk "libpango libatk libgtkhicolor"

configure-libgtk() {
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
		--without-libtiff \
		$extras	
	export LDFLAGS="$LDFLAGS_BASE"
}
PACKAGES+=" libgtkhicolor"
hset url libgtkhicolor "http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.12.tar.gz"

deploy-libgtk() {
	deploy cp -r "$STAGING_USR"/etc/gtk-2.0 "$ROOTFS"/etc
	rsync -av \
		"$STAGING_USR/share/icons" \
		"$STAGING_USR/share/themes" \
		"$ROOTFS/usr/share/" \
			&>> "$LOGFILE" 
}

PACKAGES+=" librsvg"
hset url librsvg "http://ftp.gnome.org/pub/gnome/sources/librsvg/2.26/librsvg-2.26.0.tar.bz2"
hset depends librsvg "libxml2 libgtk"

configure-librsvg() {
	export LDFLAGS="$LDFLAGS_RLINK"
	if [[ $TARGET_X11 ]]; then
		extras="--with-x"
	else
		extras="--without-x"
	fi
	configure-generic \
		--with-defaults \
		--without-croco \
		--without-svgz \
		--disable-mozilla-plugin \
		$extras 
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-librsvg() {
	deploy cp "$STAGING_USR"/bin/rsvg-view "$ROOTFS/usr/bin/"
}
