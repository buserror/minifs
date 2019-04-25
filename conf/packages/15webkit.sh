
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


# http://site.icu-project.org/
PACKAGES+=" libicu"
hset libicu url "http://download.icu-project.org/files/icu4c/51.1/icu4c-51_1-src.tgz"
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

PACKAGES+=" libwebp"
#hset libwebp url "https://webp.googlecode.com/files/libwebp-0.2.1.tar.gz"
hset libwebp url "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/archive/libwebp-0.2.1.tar.gz"
PACKAGES+=" libsecret"
#hset libsecret url "http://ftp.de.debian.org/debian/pool/main/libs/libsecret/libsecret_0.15.orig.tar.xz"
hset libsecret url "http://ftp.de.debian.org/debian/pool/main/libs/libsecret/libsecret_0.18.5.orig.tar.xz"
hset libsecret depends "libgcrypt"

PACKAGES+=" libwebkit"
#hset libwebkit url "git!git://git.webkit.org/WebKit.git#libwebkit-git.tar.bz2"
#hset libwebkit url "git!git://gitorious.org/webkit/webkit.git#libwebkit-git.tar.bz2"
#hset libwebkit url "http://ftp.de.debian.org/debian/pool/main/w/webkit/webkit_1.8.1.orig.tar.xz"
#hset libwebkit url "http://ftp.de.debian.org/debian/pool/main/w/webkitgtk/webkitgtk_1.11.91.orig.tar.xz"
# this one is buggy
#hset libwebkit url "http://ftp.de.debian.org/debian/pool/main/w/webkitgtk/webkitgtk_2.2.2.orig.tar.xz"
#hset libwebkit url "http://ftp.de.debian.org/debian/pool/main/w/webkitgtk/webkitgtk_2.4.2.orig.tar.xz"
#NOTE: we can also use "https://webkitgtk.org/releases/webkitgtk-2.4.9.tar.xz" in case the Debian link disappears
hset libwebkit url "http://ftp.de.debian.org/debian/pool/main/w/webkitgtk/webkitgtk_2.4.9.orig.tar.xz"
hset libwebkit depends "libicu libenchant libsoup sqlite3 libxslt libgail libgtk libwebp libsecret"

hostcheck-libwebkit() {
	hostcheck_commands gperf
}

# needs on the host
# gtk-docize
# gperf
configure-libwebkit() {
#	local extras="--enable-debug"
	local extras=""
	export LDFLAGS="$LDFLAGS_RLINK"
	# GTKlauncher still want GST, even when no video is not configured
	sed -i -e '/gst/d' Tools/GtkLauncher/main.c
	# 2.2.2 has hardcoded pathnames
	sed -i -e 's|<freetype/|<|g' \
		./Source/WebCore/platform/graphics/harfbuzz/HarfBuzzFaceCairo.cpp
	save=$CFLAGS
	if [[ ! $TARGET_X11 ]]; then
		# ENABLE_NETSCAPE_PLUGIN_API
		extras+="--with-target=directfb"
		CXXFLAGS="$CFLAGS -DENABLE_NETSCAPE_PLUGIN_API=0"
		export CFLAGS CXXFLAGS
	fi
	configure-generic \
		--disable-glibtest \
		--disable-video \
		--disable-webgl \
		--disable-media-stream \
		--disable-web-audio \
		--disable-geolocation \
		--disable-gtk-doc-html \
		--disable-webkit2 \
		--disable-svg \
		--disable-spellcheck \
		--with-gtk=2.0 \
		$extras WTF_USE_WEBP=0
	CFLAGS=$save
	CXXFLAGS=$save
	export LDFLAGS="$LDFLAGS_BASE"
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
hset flashplugin phases "deploy"
hset flashplugin depends "gnutls libcurl libnss msfonts libwebkit"
# get the stable release -- 10.3.181.14 as of 18/05/12
#hset flashplugin url "http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_10_linux.tar.gz#flashplugin-10.3-$TARGET_ARCH.tarb"
# 64 bits player 11 beta 2
#hset flashplugin url "http://download.macromedia.com/pub/labs/flashplatformruntimes/flashplayer11/flashplayer11_b2_install_lin_64_080811.tar.gz#flashplugin-11b2-$TARGET_ARCH.tarb"
# 64 bits player 11 RC
#hset flashplugin url "http://download.macromedia.com/pub/labs/flashplatformruntimes/flashplayer11/flashplayer11_rc1_install_lin_64_090611.tar.gz#flashplugin-11rc1-$TARGET_ARCH.tarb"
# 11 final 11.1.102.55
#hset flashplugin url "http://fpdownload.macromedia.com/get/flashplayer/pdc/11.1.102.55/install_flash_player_11_linux.$TARGET_ARCH.tar.gz#flashplugin-11.1.102.55-$TARGET_ARCH.tarb"
# 11.2 beta with multithread decoder
hset flashplugin url "http://download.macromedia.com/pub/labs/flashplatformruntimes/flashplayer11-2/flashplayer11-2_p5_install_lin_64_013112.tar.gz"

deploy-flashplugin-local() {
	mkdir -p "$ROOTFS"/usr/lib/mozilla/plugins/
	cp *.so "$ROOTFS"/usr/lib/mozilla/plugins/
	ROOTFS_PLUGINS+="$ROOTFS/usr/lib/mozilla/plugins/:"
	# these are not loaded automaticaly
	ROOTFS_KEEPERS+="libcurl.so.4:libcurl-gnutls.so.4:libasound.so.2:"
}
deploy-flashplugin() {
	touch ._install_flashplugin
	deploy deploy-flashplugin-local
}
