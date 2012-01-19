


PACKAGES+=" libvncserver"
hset libvncserver url "http://downloads.sourceforge.net/project/libvncserver/libvncserver/0.9.7/LibVNCServer-0.9.7.tar.gz"
#hset libvncserver url "http://downloads.sourceforge.net/project/libvncserver/libvncserver/0.9.8.2/LibVNCServer-0.9.8.2.tar.gz"
hset libvncserver depends "zlib libjpeg"
hset libvncserver configscript "libvncserver-config"
hset libvncserver optional "libsdl xorglibX11 libgcrypt"

configure-libvncserver-local() {
	set -x
	local extras=""

	export LDFLAGS="$LDFLAGS_RLINK"

	# that bit needs SDL somehow. we don't want it if SDL not built
	if ! env_contains TARGET_PACKAGES libsdl ; then 
		echo libvncserver Disabling SDL 
		sed -i -e 's|client_examples||g' \
			Makefile.am
		sed -i -e "/client_examples\/Makefile/d" \
			configure.ac
	fi
	if env_contains TARGET_PACKAGES xorglibX11 ; then 
		if env_contains TARGET_PACKAGES libxcb; then
			LDFLAGS+=" -lxcb"
		fi
	fi
	if ! env_contains TARGET_PACKAGES libgcrypt; then
		extras+=" --without-gcrypt"
	fi
	echo libvncserver Disabling x11vnc 
	extras+=" --without-x11vnc"
	sed -i -e 's|x11vnc||g' \
			Makefile.am
	sed -i -e "s|[ \t]\(AC_CONFIG_FILES(\[x11vnc/Makefile\)|true #\1|g" \
			configure.ac
	
	libtoolize && $ACLOCAL && autoheader && automake --force-missing --foreign -a -c && autoconf
	configure-generic-local $extras
	# 0.9.8.2 uses some crap windows file because of /* #undef LIBVNCSERVER_HAVE_GETTIMEOFDAY */
	sed -i -e 's|/\* #undef LIBVNCSERVER_HAVE_GETTIMEOFDAY \*/|#define LIBVNCSERVER_HAVE_GETTIMEOFDAY 1|' rfb/rfbconfig.h
	export LDFLAGS="$LDFLAGS_BASE"
	set +x
}

configure-libvncserver() {
	configure configure-libvncserver-local
}

install-libvncserver-local() {
	install-generic-local
	viewer=client_examples/.libs/SDLvncviewer
	if [ -x $viewer ]; then
		cp $viewer "$STAGING_USR"/bin
	fi
}
install-libvncserver() {
	install-generic install-libvncserver-local
}

deploy-libvncserver() {
	viewer="$STAGING_USR"/bin/SDLvncviewer
	if [ -x $viewer ]; then
		deploy cp $viewer "$ROOTFS"/usr/bin
	fi
}

PACKAGES+=" x11vnc"
hset x11vnc url "http://downloads.sourceforge.net/project/libvncserver/x11vnc/0.9.12/x11vnc-0.9.12.tar.gz"
hset x11vnc depends "libvncserver"

configure-x11vnc() {
	export LDFLAGS="$LDFLAGS_RLINK -lxcb"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"	
}

deploy-x11vnc() {
	deploy deploy_binaries
}
