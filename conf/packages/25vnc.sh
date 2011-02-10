


PACKAGES+=" libvncserver"
hset libvncserver url "http://downloads.sourceforge.net/project/libvncserver/libvncserver/0.9.7/LibVNCServer-0.9.7.tar.gz"
hset libvncserver depends "zlib libjpeg"

configure-libvncserver-local() {
	set -x
	local extras=""
	local sdl=$(echo $TARGET_PACKAGES|awk '/libsdl/{print "found"}')
	local xorg="not there"
	# that bit needs SDL somehow. we don't want it if SDL not built
	if [ "$sdl" != "found" ]; then
		echo libvncserver Disabling SDL 
		sed -i -e 's|client_examples||g' \
			Makefile.am
		sed -i -e "/client_examples\/Makefile/d" \
			configure.ac
	fi
	if [ "$xorg" != "found" ]; then
		echo libvncserver Disabling x11vnc 
		extras="--without-x11vnc"
		sed -i -e 's|x11vnc||g' \
				Makefile.am
		sed -i -e "s|[ \t]\(AC_CONFIG_FILES(\[x11vnc/Makefile\)|true #\1|g" \
				configure.ac
	fi
	libtoolize && $ACLOCAL && autoheader && automake --force-missing --foreign -a -c && autoconf
	configure-generic-local $extras
	set +x
}

configure-libvncserver() {
	configure configure-libvncserver-local
}

install-libvncserver() {
	install-generic
	sed -i -e "s|prefix=/usr|prefix=$STAGING_USR|g" \
		"$STAGING_USR"/bin/libvncserver-config
	viewer=client_examples/.libs/SDLvncviewer
	if [ -x $viewer ]; then
		cp $viewer "$STAGING_USR"/bin
	fi
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
#hset x11vnc dir "libvncserver"
#hset x11vnc phases "deploy"

configure-x11vnc() {
	export LDFLAGS="$LDFLAGS_RLINK -lxcb"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"	
}

deploy-x11vnc() {
	deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
}
