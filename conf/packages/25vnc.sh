


PACKAGES+=" libvncserver"
hset libvncserver url "http://downloads.sourceforge.net/project/libvncserver/libvncserver/0.9.7/LibVNCServer-0.9.7.tar.gz"
hset libvncserver depends "zlib libjpeg"

configure-libvncserver-local() {
	set -x
	sdl=$(echo $TARGET_PACKAGES|awk '/libsdl/{print "found"}')
	# that bit needs SDL somehow. we don't want it if SDL not built
	if [ "$sdl" != "found" ]; then
		sed -i -e 's|client_examples||g' \
			Makefile.am
		sed -i -e "/client_examples\/Makefile/d" \
			configure.ac
	fi
	sed -i -e 's|x11vnc||g' \
			Makefile.am
	sed -i -e "s|[ \t]\(AC_CONFIG_FILES(\[x11vnc/Makefile\)|true #\1|g" \
			configure.ac
	rm -f configure # make sure it's redone
	autoreconf --force
	configure-generic-local \
		--without-x11vnc
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
