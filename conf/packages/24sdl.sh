

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

PACKAGES+=" libsdlimage"
hset libsdlimage url "http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.10.tar.gz"
hset libsdlimage depends "libsdl libpng"

setup-libsdlimage() {
	# SDL_image manualy load shared libs, they are not (GGRRRRR!) in ELF 
	ROOTFS_KEEPERS+="libpng14.so:libjpeg.so:"
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

PACKAGES+=" kobodeluxe"
hset kobodeluxe url "http://olofson.net/kobodl/download/KoboDeluxe-0.5.1.tar.bz2"
hset kobodeluxe depends "libsdlimage"

configure-kobodeluxe-local() {
	set -x
	export SDL_CONFIG="$STAGING_TOOLS"/bin/sdl-config
	export LDFLAGS="$LDFLAGS_RLINK"
	libtoolize && aclocal && autoheader && automake --force-missing --foreign -a -c && autoconf
	configure-generic-local \
		--disable-opengl
	export LDFLAGS="$LDFLAGS_BASE"
	unset SDL_CONFIG
	set +x
}

configure-kobodeluxe() {
	configure configure-kobodeluxe-local
}

deploy-kobodeluxe() {
	deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
	cp -rf "$STAGING_USR"/com "$ROOTFS"/usr/
	cp -rf "$STAGING_USR"/share/kobo-deluxe "$ROOTFS"/usr/share/
	
}
