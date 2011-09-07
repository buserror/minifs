
PACKAGES+=" libenchant"
V="1.5.0"
hset libenchant version $V
hset libenchant url "http://www.abisource.com/downloads/enchant/1.5.0/enchant-$V.tar.gz"

PACKAGES+=" libxslt"
V="1.1.22"
hset libxslt version $V
hset libxslt url "ftp://ftp.gnome.org/pub/GNOME/sources/libxslt/1.1/libxslt-$V.tar.bz2"
hset libxslt depends "libxml2"
hset libxslt configscript "xslt-config"

configure-libxslt() {
	configure-generic --without-crypto --without-python \
		--with-libxml-prefix="$STAGING_USR"
}

# for gst-plugins-base etc
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

# http://gstreamer.freedesktop.org/
CONFIG_GSTREAMER_VERSION=0.10.35

PACKAGES+=" gstreamer gst-plugins-base"
hset gstreamer url "http://gstreamer.freedesktop.org/src/gstreamer/gstreamer-$CONFIG_GSTREAMER_VERSION.tar.bz2"
hset gst-plugins-base url "http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-$CONFIG_GSTREAMER_VERSION.tar.bz2"
hset gst-plugins-base depends "liboil libalsa libogg libvorbis"
hset gstreamer targets "gstreamer gst-plugins-base"

setup-gstreamer() {
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/gstreamer-0.10:"
}

configure-gstreamer() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic --libexecdir="$STAGING_USR"/lib
	export LDFLAGS="$LDFLAGS_BASE"
}

configure-gst-plugins-base() {
	export LDFLAGS="$LDFLAGS_RLINK"
	if [[ $TARGET_X11 ]]; then
		export LDFLAGS="$LDFLAGS -lxcb"
	fi
	configure-generic --without-x --without-gudev --disable-nls
	export LDFLAGS="$LDFLAGS_BASE"
}

# http://site.icu-project.org/
PACKAGES+=" libicu"
hset libicu url "http://download.icu-project.org/files/icu4c/4.2.1/icu4c-4_2_1-src.tgz"
#hset libicu url "http://download.icu-project.org/files/icu4c/4.4.2/icu4c-4_4_2-src.tgz"
hset libicu dir "libicu/source"
hset libicu configscript "icu-config"


# libicu needs a host version of itself
configure-libicu-local() {
	set -x
	sed -i -e 's|BITS_GOT=unknown|&;DEFAULT_64BIT=no|' configure
	if [ ! -d ../host ]; then
		mkdir -p ../host
		( pushd ../host
		unset CC CXX CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
		../source/runConfigureICU Linux \
			--disable-tests --disable-samples \
			&& make -j8
		)
	fi
	../source/runConfigureICU Linux \
		--build=$(uname -m) \
		--host=$TARGET_FULL_ARCH \
		--prefix="$PACKAGE_PREFIX" \
		--with-cross-build=$(pwd)/../host \
		--disable-tests --disable-samples \
		CC="${CROSS}-gcc" CXX="${CROSS}-g++"
	set +x
}
configure-libicu() {
	configure configure-libicu-local
}


PACKAGES+=" libwebkit"
#hset libwebkit url "git!git://git.webkit.org/WebKit.git#libwebkit-git.tar.bz2"
hset libwebkit url "git!git://gitorious.org/webkit/webkit.git#libwebkit-git.tar.bz2"
hset libwebkit depends "libicu libenchant libsoup sqlite3 libxslt libgtk gstreamer gst-plugins-base"

hostcheck-libwebkit() {
	hostcheck_commands gperf
}

# needs on the host
# gtk-docize 
# gperf
configure-libwebkit() {
#	local extras="--enable-debug"
	local extras=""
	save=$CFLAGS
	if [[ ! $TARGET_X11 ]]; then
		# ENABLE_NETSCAPE_PLUGIN_API
		extras+="--with-target=directfb"
		CXXFLAGS="$CFLAGS -DENABLE_NETSCAPE_PLUGIN_API=0"
		export CFLAGS CXXFLAGS
	fi
	configure-generic \
		--disable-glibtest \
		--disable-gtk-doc-html \
		$extras
	CFLAGS=$save
	CXXFLAGS=$save
}
deploy-libwebkit() {
	deploy cp Programs/GtkLauncher "$ROOTFS"/usr/bin/
}

PACKAGES+=" msfonts"
hset msfonts url "http://oomz.net/git/msttcorefonts.tar.bz2"
hset msfonts phases "deploy"

deploy-msfonts() {
	deploy echo Deploying
	mkdir -p "$ROOTFS"/usr/share/fonts/ 
	rsync -av truetype "$ROOTFS"/usr/share/fonts/ >install.log 2>&1
}

PACKAGES+=" flashplugin"
# get the stable release -- 10.3.181.14 as of 18/05/12
hset flashplugin url "http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_10_linux.tar.gz#flashplugin-10.3.tarb"

hset flashplugin phases "deploy"
hset flashplugin depends "gnutls libcurl libnss msfonts libwebkit"

deploy-flashplugin() {
	deploy echo Deploying flashplugin
	mkdir -p "$ROOTFS"/usr/lib/mozilla/plugins/
	cp *.so "$ROOTFS"/usr/lib/mozilla/plugins/
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/mozilla/plugins/:"
	# these are not loaded automaticaly
	ROOTFS_KEEPERS+="libcurl.so.4:libcurl-gnutls.so.4:libasound.so.2:"
}

