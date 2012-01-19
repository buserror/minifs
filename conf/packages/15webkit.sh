
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
hset libwebkit depends "libicu libenchant libsoup sqlite3 libxslt libgail libgtk gstreamer"

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
		--disable-webkit2 \
		--with-gtk=2.0 \
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
hset flashplugin url "http://download.macromedia.com/pub/labs/flashplatformruntimes/flashplayer11-2/flashplayer11-2_p2_install_lin_64_112211.tar.gz"

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

