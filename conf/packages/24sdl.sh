

PACKAGES+=" libsdl"
hset libsdl url "http://www.libsdl.org/release/SDL-1.2.14.tar.gz"

configure-libsdl() {
	local extras=""
	if ! env_contains TARGET_PACKAGES xorgserver ; then
		extras+="--without-x"
	fi
	configure-generic \
		$extras \
		--enable-arts=no \
		--enable-esd=no \
		--enable-pulseaudio=no \
		--enable-video-directfb=no
}
install-libsdl-local() {
	install-generic-local
	# can't use the 'configscript' option here
	sed -e "s|prefix=/usr|prefix=$STAGING_USR|g" \
		-e "s|-lm .*$||g" \
		"$STAGING_USR"/bin/sdl-config \
			>"$STAGING_TOOLS"/bin/sdl-config && \
		chmod +x "$STAGING_TOOLS"/bin/sdl-config
}
install-libsdl() {
	log_install install-libsdl-local
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
hset sdlplasma depends "libsdl"

configure-sdlplasma() {
	export LDFLAGS="$LDFLAGS_RLINK -lm"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"
}
deploy-sdlplasma() {
        deploy deploy_binaries
}

PACKAGES+=" sdlvoxel"
hset sdlvoxel url "http://www.libsdl.org/projects/newvox/src/newvox-1.0.tar.gz"
hset sdlvoxel depends "libsdl"

configure-sdlvoxel() {
	export LDFLAGS="$LDFLAGS_RLINK -lm"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-sdlvoxel() {
        deploy deploy_binaries
}

PACKAGES+=" kobodeluxe"
hset kobodeluxe url "http://olofson.net/kobodl/download/KoboDeluxe-0.5.1.tar.bz2"
hset kobodeluxe depends "libsdlimage"

configure-kobodeluxe-local() {
	set -x
	# conflicts with uclibc pipe2() function
	sed -i -e 's|pipe2|pipe_2|g' enemies.h enemy.cpp
	export SDL_CONFIG="$STAGING_TOOLS"/bin/sdl-config
	export LDFLAGS="$LDFLAGS_RLINK"
	libtoolize && $ACLOCAL && autoheader && automake --force-missing --foreign -a -c && autoconf
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
	deploy deploy_binaries
	cp -rf "$STAGING_USR"/com "$ROOTFS"/usr/
	cp -rf "$STAGING_USR"/share/kobo-deluxe "$ROOTFS"/usr/share/
	
}
