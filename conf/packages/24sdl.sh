

PACKAGES+=" libsdl"
hset libsdl url "http://www.libsdl.org/release/SDL-1.2.14.tar.gz"

configure-libsdl() {
	configure-generic \
		--without-x \
		--enable-arts=no \
		--enable-esd=no \
		--enable-pulseaudio=no \
		--enable-video-directfb=no
}

install-libsdl() {
	install-generic
	sed -i -e "s|prefix=/usr|prefix=$STAGING_USR|g" \
		-e "s|-lm .*$||g" \
		"$STAGING_USR"/bin/sdl-config
	sed -i -e "s|-lm .*'|'|g" \
		"$STAGING_USR"/lib/libSDL.la
	cp "$STAGING_USR"/bin/sdl-config "$STAGING_TOOLS"/bin
}

PACKAGES+=" sdlquake"
hset sdlquake url "http://www.libsdl.org/projects/quake/src/sdlquake-1.0.9.tar.gz"
hset sdlquake depends "libsdl"

configure-sdlquake() {
	autoconf
	configure-generic \
		--disable-asm
}

PACKAGES+=" sdlplasma"
hset sdlplasma url "http://www.libsdl.org/projects/plasma/src/plasma-1.0.tar.gz"

deploy-sdlplasma() {
        deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
}

PACKAGES+=" sdlvoxel"
hset sdlvoxel url "http://www.libsdl.org/projects/newvox/src/newvox-1.0.tar.gz"

deploy-sdlvoxel() {
        deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
}

