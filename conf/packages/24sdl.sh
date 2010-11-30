

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
hset sdlquake url "https://sites.google.com/site/repurposelinux/df3120/sdlquake-1.0.9.tar.gz"
hset sdlquake depends "libsdl"

configure-sdlquake() {
	autoconf
	configure-generic --enable-asm=no
}
