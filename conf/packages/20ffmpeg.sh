
#######################################################################
## for hardware decoding
#######################################################################
# http://cgit.freedesktop.org/libva/
PACKAGES+=" libva"
hset libva url "http://cgit.freedesktop.org/libva/snapshot/libva-1.0.15.tar.bz2"
hset libva optional "xorglibX11"

configure-libva() {
	export LDFLAGS="$LDFLAGS_RLINK"
	if env_contains TARGET_PACKAGES libxcb ; then 
		LDFLAGS+=" -lxcb"
	fi
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libvdpau"
hset libvdpau url "http://cgit.freedesktop.org/~aplattner/libvdpau/snapshot/libvdpau-0.4.1.tar.bz2"
hset libvdpau optional "nvidia"

# we don't want this library to clobber the nvidia one, so we install
# only the headers 
install-libvdpau() {
	if env_contains TARGET_PACKAGES nvidia ; then 
		log_install cp -r include/vdpau "$STAGING_USR"/include/
	else
		install-generic
	fi
}

PACKAGES+=" libva-vdpau"
hset libva-vdpau url "http://cgit.freedesktop.org/vaapi/vdpau-driver/snapshot/vdpau-driver-0.7.3.tar.bz2"
hset libva-vdpau depends "libva libvdpau nvidia"


#######################################################################
## for gst-plugins-base etc
#######################################################################
PACKAGES+=" liboil"
hset liboil url "http://liboil.freedesktop.org/download/liboil-0.3.17.tar.gz"

configure-liboil-local() {
	# fix 64 bits build
	sed -i -e 's/64|/64*|/g' m4/as-unaligned-access.m4
	rm -f configure
	configure-generic-local
}

configure-liboil() {
	configure configure-liboil-local
}

PACKAGES+=" libogg"
hset libogg url "http://downloads.xiph.org/releases/ogg/libogg-1.1.4.tar.gz"

PACKAGES+=" libvorbis"
hset libvorbis url "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.2.tar.gz"

configure-libvorbis() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"
}

# for gst-plugins-base
# http://code.entropywave.com/projects/orc/
PACKAGES+=" orc"
hset orc url "http://code.entropywave.com/download/orc/orc-0.4.16.tar.gz"

#######################################################################
## gstreamer
#######################################################################
# http://gstreamer.freedesktop.org/
CONFIG_GSTREAMER_VERSION=0.10.35

PACKAGES+=" gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly"
hset gstreamer url "http://gstreamer.freedesktop.org/src/gstreamer/gstreamer-$CONFIG_GSTREAMER_VERSION.tar.bz2"
hset gst-plugins-base url "http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-$CONFIG_GSTREAMER_VERSION.tar.bz2"
hset gst-plugins-base depends "gstreamer liboil libalsa libogg libvorbis orc"
hset gst-plugins-good url "http://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-0.10.30.tar.bz2"
hset gst-plugins-good depends "gstreamer"
hset gst-plugins-bad url "http://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-0.10.22.tar.bz2"
hset gst-plugins-bad depends "gstreamer"
hset gst-plugins-ugly url "http://gstreamer.freedesktop.org/src/gst-plugins-ugly/gst-plugins-ugly-0.10.18.tar.bz2"
hset gst-plugins-ugly depends "gstreamer gst-plugins-base libx264"
hset gstreamer targets "gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly"
hset gstreamer optional "ffmpeg xorglibX11 libva"

setup-gstreamer() {
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/gstreamer-0.10:"
}

configure-gstreamer() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic --libexecdir="$STAGING_USR"/lib
	export LDFLAGS="$LDFLAGS_BASE"
}

configure-gst-plugins-base() {
	local extra=""
	export LDFLAGS="$LDFLAGS_RLINK"
	if [[ $TARGET_X11 ]]; then
		export LDFLAGS="$LDFLAGS -lxcb"
	else
		extra="--without-x "
	fi
	configure-generic --without-gudev --disable-nls $extra
	export LDFLAGS="$LDFLAGS_BASE"
}
configure-gst-plugins-good() {
	configure-generic --without-gudev --disable-nls --disable-shout2
}

#######################################################################
## libx264
#######################################################################
PACKAGES+=" libx264"
hset libx264 url "ftp://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20111213-2245-stable.tar.bz2"

configure-libx264() {
	configure-generic --enable-shared --enable-pic
}

PACKAGES+=" libfaac"
hset libfaac url "http://downloads.sourceforge.net/faac/faac-1.28.tar.bz2"

patch-libfaac() {
	sed -i -e '/char \*strcasestr/d' common/mp4v2/mpeg4ip.h
}

PACKAGES+=" libxvid"
hset libxvid url "http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.bz2"
hset libxvid dir "libxvid/build/generic"

#######################################################################
## ffmpeg
#######################################################################
PACKAGES+=" ffmpeg"

V="0.9"
hset ffmpeg version $V
hset ffmpeg url "http://ffmpeg.org/releases/ffmpeg-$V.tar.bz2"
hset ffmpeg depends "busybox"
hset ffmpeg optional "libx264 libfaac libxvid nvidia libfreetype"
hset ffmpeg destdir "none"

hostcheck-ffmpeg() {
	hostcheck_commands yasm
}

configure-ffmpeg() {
	local extra=""
	extra="--arch=$TARGET_ARCH"
	extra+=" --enable-static --enable-shared --enable-pic --enable-nonfree"

	if env_contains TARGET_PACKAGES libx264 ; then
		extra+=" --enable-libx264"
	fi
	if env_contains TARGET_PACKAGES libfaac ; then
		extra+=" --enable-libfaac"
	fi
	if env_contains TARGET_PACKAGES libxvid ; then
		extra+=" --enable-libxvid"
	fi
	if env_contains TARGET_PACKAGES libfreetype ; then
		true #	extra+=" --enable-libfreetype"
	fi
	export LDFLAGS="$LDFLAGS_RLINK"
	configure ./configure \
		--prefix="$STAGING" \
		--enable-cross-compile \
		--target-os=linux \
		--cross-prefix="${CROSS}-" \
		--host-cc="$GCC" \
		--disable-ffplay --disable-ffserver \
		--enable-gpl --enable-swscale --enable-pthreads \
		--enable-fastdiv --enable-small \
		--enable-hardcoded-tables \
		--enable-avcodec \
		$extra
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libmad"
hset libmad url "http://downloads.sourceforge.net/project/mad/libmad/0.15.1b/libmad-0.15.1b.tar.gz"

configure-libmad() {
	configure-generic --enable-aso --enable-sso
}

# http://liba52.sourceforge.net/ -- AC3 library
PACKAGES+=" liba52"
hset liba52 url "http://liba52.sourceforge.net/files/a52dec-0.7.4.tar.gz"

# http://fribidi.org/ -- Unicode Bidirectional Algorithm (bidi).
PACKAGES+=" fribidi"
hset fribidi url "http://fribidi.org/download/fribidi-0.10.9.tar.gz"

PACKAGES+=" vlc"
V="1.1.13"
hset vlc url "http://download.videolan.org/pub/videolan/vlc/$V/vlc-$V.tar.bz2"
hset vlc depends "zlib ffmpeg libmad libfaac libxvid liba52 fribidi xcb-util-keysyms"

patch-vlc() {
	sed -i -e "s|-fforce-mem||g" configure
}
configure-vlc() {
	configure-generic --disable-dbus-control --disable-dbus \
		--disable-lua \
		--disable-qt4 --disable-skins2
}
