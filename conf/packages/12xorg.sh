

# http://cgit.freedesktop.org/xorg/util/modular/plain/module-list.txt?h=XORG-7_5
#XORG_VERSION=XORG-7_5

# http://cgit.freedesktop.org/xorg/util/modular/plain/module-list.txt?h=X11R7.6
XORG_VERSION=X11R7.6


XORG_MODULES=""

xorg_module_geturl() {
	local path=$1
	local module=$2

	if [ "$XORG_MODULES" == "" ]; then
		XORG_MODULES=$(cat "$CONF_BASE/packages/module-list-$XORG_VERSION.txt"|tr "\n" " ")
	fi
	mod=$(echo $XORG_MODULES|awk "{c=split(\$0,a); for(i=0;i<c;i++) if(match(a[i],/^$module-/)) print a[i] ;}")
	url="http://xorg.freedesktop.org/archive/individual/$path/$mod.tar.bz2#xorg-$mod.tar.bz2"
	echo $url
}

PACKAGES+=" xorgmacros"
hset xorgmacros url $(xorg_module_geturl "util" "util-macros")

XORG_LIBS=""
XORG_PROTOS=""
XORG_FONTS=""
# trapproto, xf86miscproto, evieext removed
for p in \
		xproto dri2proto glproto xextproto bigreqsproto \
		xcmiscproto fontsproto inputproto kbproto resourceproto \
		scrnsaverproto videoproto recordproto  \
		xf86bigfontproto xf86dgaproto  \
		xf86vidmodeproto xf86driproto \
		compositeproto damageproto fixesproto randrproto renderproto \
		xineramaproto \
; do
	XORG_PROTOS+=" xorg$p"
	hset xorg$p url $(xorg_module_geturl "proto" $p)
	hset xorg$p depends "xorgmacros"
done
PACKAGES+=" $XORG_PROTOS"
# make this one depends on all the others
hset xorgxproto depends "$XORG_PROTOS"

# these are a bit special, they are needed by libxcb :/
XCB_LIBS=""
for p in libXau ; do
	XCB_LIBS+=" xorg$p"
	hset xorg$p url $(xorg_module_geturl "lib" $p)
	hset xorg$p depends "xorgxproto"
done
PACKAGES+=" $XCB_LIBS"

PACKAGES+=" libpthreadstubs xcbproto libxcb xkeyboardconfig"
hset libpthreadstubs url "http://xcb.freedesktop.org/dist/libpthread-stubs-0.3.tar.gz"
hset xcbproto url "http://xcb.freedesktop.org/dist/xcb-proto-1.6.tar.gz"
hset libxcb url "http://xcb.freedesktop.org/dist/libxcb-1.5.tar.bz2"
hset libxcb depends "libpthreadstubs xcbproto $XCB_LIBS"
hset xkeyboardconfig url "http://xlibs.freedesktop.org/xkbdesc/xkeyboard-config-1.7.tar.bz2"

PACKAGES+=" xtrans" 
hset xtrans url $(xorg_module_geturl "lib" "xtrans")

# libXfont needs "xmlto" tool on the host
for p in  libXdmcp libX11 libfontenc libXfont libxkbfile \
		libXrender libXft libXext libXfixes libXcursor libXdamage \
		libXrandr libXcomposite libXinerama \
		libXxf86vm libICE libSM libXt libXmu libXi libXv libXvMC \
		libpciaccess libXtst \
		 ; do
	XORG_LIBS+=" xorg$p"
	hset xorg$p url $(xorg_module_geturl "lib" $p)
done
# stupid documentation breaks build
configure-xorglibXfont() {
	configure-generic --without-xmlto --without-fop
}

hset xorglibX11 depends "libxcb xtrans xorgxproto $XORG_LIBS"

configure-xorglibXt() {
	configure-generic
	sed -i -e "s|^CFLAGS = .*|CFLAGS =|g" util/Makefile
}

configure-xorglibXfont() {
	configure-generic \
		--with-fop=no
}

configure-xorglibSM() {
	save=$CFLAGS
	CFLAGS+=" -fPIC"
	configure-generic
	CFLAGS=$save	
}

XORG_FONTS+=" xorgfontutil xorgfontadobe"
hset xorgfontutil url $(xorg_module_geturl "font" "font-util")
hset xorgfontadobe url $(xorg_module_geturl "font" "font-adobe-100dpi")

configure-xorgfontadobe() {
	configure-generic --with-fontrootdir="/usr/share/fonts"
}

PACKAGES+=" $XORG_LIBS $XORG_FONTS"

PACKAGES+=" xkbcomp" 
hset xkbcomp url $(xorg_module_geturl "app" "xkbcomp")
hset xkbcomp depends "xkeyboardconfig xorglibxkbfile"

configure-xkbcomp() {
	export LDFLAGS="$LDFLAGS_RLINK -lxcb"
	rm -f configure
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"	
}
deploy-xkbcomp() {
	deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
}

# http://cgit.freedesktop.org/mesa/drm
PACKAGES+=" libmesadrm"
#hset libmesadrm url "git!git://anongit.freedesktop.org/git/mesa/drm#libmesadrm-git.tar.bz2"
hset libmesadrm url "http://cgit.freedesktop.org/mesa/drm/snapshot/drm-2.4.24.tar.gz"

configure-libmesadrm() {
	configure-generic \
		--enable-nouveau-experimental-api \
		--with-kernel-source ../linux/
}

# http://cgit.freedesktop.org/mesa/mesa/
PACKAGES+=" libmesa"
#hset libmesa url "ftp://ftp.freedesktop.org/pub/mesa/7.7.1/MesaLib-7.7.1.tar.bz2"
hset libmesa url "http://cgit.freedesktop.org/mesa/mesa/snapshot/mesa-7.9.2.tar.gz"

hset libmesa depends "libtalloc libmesadrm xorglibX11"

configure-libmesa-local() {
	export X11_LIBS="" # needs that otherwise the config/compile fails
	configure-generic-local \
		--with-dri-drivers="swrast" \
		--disable-gallium \
		--without-demos
}

configure-libmesa() {
	configure configure-libmesa-local
}

compile-libmesa() {
#	export LDFLAGS="$LDFLAGS_RLINK"
	compile-generic APP_CC=$GCC # APP_CFLAGS=
#	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libsha1"
hset libsha1 url "git!git://github.com/dottedmag/libsha1.git#libsha1-git.tar.bz2"

PACKAGES+=" xorgserver"
#hset xorgserver url "git!git://anongit.freedesktop.org/xorg/xserver#xorgserver-git.tar.bz2"
hset xorgserver url $(xorg_module_geturl "xserver" "xorg-server")
hset xorgserver depends \
	"busybox libsha1 xorglibX11 xorgfontutil \
	xkbcomp xtrans \
	xorgfontadobe \
	xorginput-evdev xorginput-keyboard xorginput-mouse \
	xorgvideo-fbdev libmesa openssl"

configure-xorgserver-local() {
	export LDFLAGS="$LDFLAGS_RLINK"
	./autogen.sh
#		--enable-kdrive --enable-kdrive-kbd --enable-kdrive-mouse --enable-kdrive-evdev 
	configure-generic-local \
		--disable-xwin --disable-xprint --disable-ipv6 \
		--disable-dmx --enable-xvfb --disable-xnest \
		--disable-dbus \
		--enable-xorg --disable-xnest \
		--with-sha1=libsha1 \
		--enable-xfbdev \
		--with-mesa-source="$BUILD/libmesa"
	export LDFLAGS="$LDFLAGS_BASE"
}
configure-xorgserver() {
	configure configure-xorgserver-local
}

deploy-xorgserver-local() {
	cp 	$(get_installed_binaries) \
		"$ROOTFS"/usr/bin/
	ln -fs Xorg "$ROOTFS"/usr/bin/X 
	rsync -av \
		"$STAGING_USR"/share/X11 \
		"$STAGING_USR"/share/fonts \
		"$STAGING_USR"/share/xcb \
		"$ROOTFS"/usr/share/
	mkdir -p "$ROOTFS"/usr/var/log
}
deploy-xorgserver() {
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/xorg:"
	deploy deploy-xorgserver-local
}

for p in \
	input-evdev input-keyboard input-mouse \
	video-fbdev video-vmware \
		 ; do
	PACKAGES+=" xorg$p"
	fname=${p//-/}
#	hset xorg$p url "git!git://anongit.freedesktop.org/git/xorg/driver/xf86-$p#xorg$fname-git.tar.bz2"
	hset xorg$p url $(xorg_module_geturl "driver" "xf86-$p")
	hset xorg$p depends "xorgserver"
done

PACKAGES+=" xorgvideo-nouveau"
hset xorgvideo-nouveau url "git!git://anongit.freedesktop.org/git/nouveau/xf86-video-nouveau#xorgvideonouveau-git.tar.bz2"
hset xorgvideo-nouveau depends "xorgserver libmesadrm"

export X11_LIBS="$STAGING_USR/lib"



configure-xorglibXvMC() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXv() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXi() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXt() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibX11() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXrender() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXrandr() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXinerama() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXext() {
	configure-generic --enable-malloc0returnsnull
}
configure-xorglibXxf86vm() {
	configure-generic --enable-malloc0returnsnull
}
