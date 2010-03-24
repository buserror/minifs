
PACKAGES+=" libenchant"
hset url libenchant "http://www.abisource.com/downloads/enchant/1.5.0/enchant-1.5.0.tar.gz"
#hset depends libwebkit "libgperf libgtk"

PACKAGES+=" libsoup"
hset url libsoup "git!git://git.gnome.org/libsoup#libsoup-git.tar.bz2"

configure-libsoup() {
	configure-generic \
		--without-gnome \
		--disable-glibtest \
		--disable-ssl
}

PACKAGES+=" sqlite3"
hset url sqlite3 "http://www.sqlite.org/sqlite-3.6.22.tar.gz"

PACKAGES+=" libxslt"
hset url libxslt "ftp://ftp.gnome.org/pub/GNOME/sources/libxslt/1.1/libxslt-1.1.22.tar.bz2"
hset depends libxslt "libxml2"

configure-libxslt() {
	configure-generic --without-crypto 
}

# for gst-plugins-base etc
PACKAGES+=" liboil"
hset url liboil "http://liboil.freedesktop.org/download/liboil-0.3.17.tar.gz"

PACKAGES+=" libalsa"
hset url libalsa "ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.0.22.tar.bz2"

deploy-libalsa() {
	deploy rsync -a "$STAGING_USR"/share/alsa "$ROOTFS"/usr/share/
}

PACKAGES+=" libogg"
hset url libogg "http://downloads.xiph.org/releases/ogg/libogg-1.1.4.tar.gz"

PACKAGES+=" libvorbis"
hset url libvorbis "http://downloads.xiph.org/releases/vorbis/libvorbis-1.2.3.tar.gz"

configure-libvorbis() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"
}

CONFIG_GSTREAMER_VERSION=0.10.26

PACKAGES+=" gstreamer gst-plugins-base"
hset url gstreamer "http://gstreamer.freedesktop.org/src/gstreamer/gstreamer-$CONFIG_GSTREAMER_VERSION.tar.bz2"
hset url gst-plugins-base "http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-$CONFIG_GSTREAMER_VERSION.tar.bz2"
hset depends gst-plugins-base "liboil libalsa libogg libvorbis gstreamer"
hset depends gstreamer "gst-plugins-base"

configure-gstreamer() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic
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

PACKAGES+=" libicu"
hset url libicu "http://download.icu-project.org/files/icu4c/4.2.1/icu4c-4_2_1-src.tgz"
hset dir libicu "libicu/source"

# libicu needs a host version of itself
configure-libicu-local() {
	sed -i -e 's|BITS_GOT=unknown|&;DEFAULT_64BIT=no|' configure
	if [ ! -d ../host ]; then
		mkdir -p ../host
		pushd ../host
		../source/runConfigureICU Linux \
			--disable-tests --disable-samples \
			&& make -j8
		popd
	fi
	../source/runConfigureICU Linux \
		--build=$(uname -m) \
		--host=$TARGET_FULL_ARCH \
		--prefix="$PACKAGE_PREFIX" \
		--with-cross-build=$(pwd)/../host \
		--disable-tests --disable-samples \
		CC="${CROSS}-gcc" CXX="${CROSS}-g++"
}
configure-libicu() {
	configure configure-libicu-local
}
install-libicu() {
	install-generic
	cp "$STAGING_USR"/bin/icu-config \
		"$TOOLCHAIN"/bin/ &&
	sed -i -e "s|default_prefix=\"/usr\"|default_prefix=\"\$STAGING_USR\"|g" \
		 "$TOOLCHAIN"/bin/icu-config
}


PACKAGES+=" libwebkit"
hset url libwebkit "git!git://git.webkit.org/WebKit.git#libwebkit-git.tar.bz2"
hset depends libwebkit "libicu libenchant libsoup sqlite3 libxslt libgtk gstreamer"

# needs on the host
# gtk-docize 
# gperf
configure-libwebkit() {
	local extras="--enable-debug"
	save=$CFLAGS
	if [[ ! $TARGET_X11 ]]; then
		# ENABLE_NETSCAPE_PLUGIN_API
		extras+="--with-target=directfb"
		CXXFLAGS="$CFLAGS -DENABLE_NETSCAPE_PLUGIN_API=0"
		export CFLAGS CXXFLAGS
	fi
	#	--with-unicode-backend=glib 
	configure-generic \
		$extras
	CFLAGS=$save
	CXXFLAGS=$save
}
deploy-libwebkit() {
	deploy cp Programs/GtkLauncher "$ROOTFS"/usr/bin/
}

PACKAGES+=" flashplugin"
#hset url flashplugin "http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_10_linux.tar.gz#flashplugin-10.tarb"
hset url flashplugin "http://download.macromedia.com/pub/labs/flashplayer10/flashplayer10_1_p3_linux_022310.tar.gz#flashplugin-10.1.tarb"
hset phases flashplugin "deploy"
hset depends flashplugin "gnutls libcurl libnss libwebkit"

deploy-flashplugin() {
	deploy echo Deploying flashplugin
	mkdir -p "$ROOTFS"/usr/lib/mozilla/plugins/
	cp *.so "$ROOTFS"/usr/lib/mozilla/plugins/
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/mozilla/plugins/:"
	# these are not loaded automaticaly
	ROOTFS_KEEPERS+="libcurl.so.4:libcurl-gnutls.so.4:libasound.so.2:"
}

