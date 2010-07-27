
PACKAGES+=" xorgmacros"
hset xorgmacros url "git!git://anongit.freedesktop.org/git/xorg/util/macros#xorgmacros-git.tar.bz2"

XORG_LIBS=""
XORG_PROTOS=""
XORG_FONTS=""

for p in \
		x11proto dri2proto glproto xextproto bigreqsproto \
		xcmiscproto fontsproto inputproto kbproto resourceproto \
		scrnsaverproto videoproto recordproto trapproto \
		xf86bigfontproto xf86dgaproto xf86miscproto \
		xf86vidmodeproto xf86driproto \
		compositeproto damageproto fixesproto randrproto renderproto \
		evieproto xineramaproto \
; do
	XORG_PROTOS+=" xorg$p"
	hset url xorg$p "git!git://anongit.freedesktop.org/git/xorg/proto/$p#xorg$p-git.tar.bz2"
	hset depends xorg$p "xorgmacros"
done
PACKAGES+=" $XORG_PROTOS"
# make this one depends on all the others
hset xorgx11proto depends "$XORG_PROTOS"

# these are a bit special, they are needed by libxcb :/
XCB_LIBS=""
for p in libXau libxtrans ; do
	XCB_LIBS+=" xorg$p"
	hset url xorg$p "git!git://anongit.freedesktop.org/git/xorg/lib/$p#xorg$p-git.tar.bz2"
	hset depends xorg$p "xorgx11proto"
done
PACKAGES+=" $XCB_LIBS"

PACKAGES+=" libpthreadstubs xcbproto libxcb xkeyboardconfig"
hset libpthreadstubs url "http://xcb.freedesktop.org/dist/libpthread-stubs-0.3.tar.gz"
hset xcbproto url "http://xcb.freedesktop.org/dist/xcb-proto-1.6.tar.gz"
hset libxcb url "http://xcb.freedesktop.org/dist/libxcb-1.5.tar.bz2"
hset libxcb depends "libpthreadstubs xcbproto $XCB_LIBS"
hset xkeyboardconfig url "http://xlibs.freedesktop.org/xkbdesc/xkeyboard-config-1.7.tar.bz2"

PACKAGES+=" xtrans" 
hset xtrans url "http://www.x.org/releases/individual/lib/xtrans-1.2.5.tar.bz2"

# libXfont needs "xmlto" tool on the host
for p in  libXdmcp libX11 libfontenc libXfont libxkbfile \
		libXrender libXft libXext libXfixes libXcursor libXdamage \
		libXrandr libXcomposite libXinerama \
		libXxf86vm libICE libSM libXt libXmu libXi libXv \
		libpciaccess \
		 ; do
	XORG_LIBS+=" xorg$p"
	hset url xorg$p "git!git://anongit.freedesktop.org/git/xorg/lib/$p#xorg$p-git.tar.bz2"
done
# stupid documentation breaks build
configure-xorglibXfont() {
	configure-generic --without-xmlto --without-fop
}
configure-xorglibX11() {
	configure-generic
	sed -i -e "s|^CFLAGS = .*|CFLAGS =|g" src/util/Makefile
}
hset xorglibX11 depends "libxcb xtrans xorgx11proto $XORG_LIBS"

configure-xorglibXt() {
	configure-generic
	sed -i -e "s|^CFLAGS = .*|CFLAGS =|g" util/Makefile
}

XORG_FONTS+=" xorgfontutil xorgfontadobe"
hset xorgfontutil url "http://www.x.org/releases/individual/font/font-util-1.1.1.tar.bz2"
hset xorgfontadobe url "http://www.x.org/releases/individual/font/font-adobe-100dpi-1.0.1.tar.bz2"

configure-xorgfontadobe() {
	configure-generic --with-fontrootdir="/usr/share/fonts"
}

PACKAGES+=" $XORG_LIBS $XORG_FONTS"

PACKAGES+=" xkbcomp" 
hset xkbcomp url "http://www.x.org/releases/individual/app/xkbcomp-1.1.1.tar.bz2"
hset xkbcomp depends "xkeyboardconfig xorglibxkbfile"

configure-xkbcomp() {
	export LDFLAGS="$LDFLAGS_RLINK -lxcb"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"	
}

PACKAGES+=" libmesadrm libmesa"
hset libmesadrm url "git!git://anongit.freedesktop.org/git/mesa/drm#libmesadrm-git.tar.bz2"
hset libmesa url "git!git://anongit.freedesktop.org/git/mesa/mesa#libmesa-git.tar.bz2"
hset libmesa depends "libmesadrm xorglibX11"

configure-libmesadrm() {
	configure-generic \
		--enable-nouveau-experimental-api \
		--with-kernel-source ../linux/
}

configure-libmesa() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic \
		--with-dri-drivers="swrast" \
		--without-demos
	export LDFLAGS="$LDFLAGS_BASE"
}
compile-libmesa() {
	export LDFLAGS="$LDFLAGS_RLINK"
	compile-generic APP_CC=gcc
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libsha1"
hset libsha1 url "git!git://github.com/dottedmag/libsha1.git#libsha1-git.tar.bz2"

PACKAGES+=" xorgserver"
hset xorgserver url "git!git://anongit.freedesktop.org/xorg/xserver#xorgserver-git.tar.bz2"
hset xorgserver depends \
	"busybox libsha1 libmesa xorglibX11 xorgfontutil \
	xkbcomp xtrans \
	xorgfontadobe \
	xorginput-evdev xorginput-keyboard xorginput-mouse \
	xorgvideo-fbdev"

configure-xorgserver-local() {
	export LDFLAGS="$LDFLAGS_RLINK"
	./autogen.sh
#		--enable-kdrive --enable-kdrive-kbd --enable-kdrive-mouse --enable-kdrive-evdev 
	configure-generic-local \
		--disable-xwin --disable-xprint --disable-ipv6 \
		--disable-dmx --disable-xvfb --disable-xnest \
		--disable-dbus \
		--enable-xorg --disable-xnest \
		--with-sha1=libsha1 \
		--disable-local-transport \
		--enable-xfbdev \
   		--disable-xorgcfg \
   		--with-mesa-source="$BUILD/libmesa"
	export LDFLAGS="$LDFLAGS_BASE"
}
configure-xorgserver() {
	configure configure-xorgserver-local
}

deploy-xorgserver-local() {
	cp 	"$STAGING_USR"/bin/X \
		"$STAGING_USR"/bin/xkbcomp \
		"$ROOTFS"/usr/bin/
	rsync -av \
		"$STAGING_USR"/share/X11 \
		"$STAGING_USR"/share/fonts \
		"$STAGING_USR"/share/xcb \
		"$ROOTFS"/usr/share/
	mkdir -p "$ROOTFS"/usr/var/log
}
deploy-xorgserver() {
	ROOTFS_PLUGINS+="$STAGING_USR/lib/xorg:"
	deploy deploy-xorgserver-local
}

for p in \
	input-evdev input-keyboard input-mouse \
	video-fbdev \
		 ; do
	PACKAGES+=" xorg$p"
	fname=${p//-/}
	hset url xorg$p "git!git://anongit.freedesktop.org/git/xorg/driver/xf86-$p#xorg$fname-git.tar.bz2"
	hset depends xorg$p "xorgserver"
done

PACKAGES+=" xorgvideo-nouveau"
hset xorgvideo-nouveau url "git!git://anongit.freedesktop.org/git/nouveau/xf86-video-nouveau#xorgvideonouveau-git.tar.bz2"
hset xorgvideo-nouveau depends "xorgserver libmesadrm"

export X11_LIBS="$STAGING_USR/lib"

