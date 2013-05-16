

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
hset libsdlimage optional "libjpeg"

setup-libsdlimage() {
	# SDL_image manualy load shared libs, they are not (GGRRRRR!) in ELF 
	ROOTFS_KEEPERS+="libpng14.so:libjpeg.so:libSDL_image.so:libSDL_image-1.2.so:"
}

PACKAGES+=" libsdlttf"
hset libsdlttf url "http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.11.tar.gz"
hset libsdlttf depends "libsdl libfreetype"

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
    # we need to run kobodeluxe with some switches, so we really need to run it with a script
    # move the binary to there
    mv "$ROOTFS"/usr/bin/kobodl "$ROOTFS"/usr/share/kobo-deluxe/
    # now create the script
    echo "#!/bin/hush" > "$ROOTFS"/usr/sbin/kobodl
    echo "cd /usr/share/kobo-deluxe/" > "$ROOTFS"/usr/sbin/kobodl
    echo "./kobodl -width 320 -height 240 -fullscreen -nosound &" > "$ROOTFS"/usr/sbin/kobodl
    #make sure the script is executable, you can now run it 
    chmod a+wrx "$ROOTFS"/usr/sbin/kobodl
	
}

PACKAGES+=" libsdlgfx"
hset libsdlgfx url "http://www.ferzkopp.net/Software/SDL_gfx-2.0/SDL_gfx-2.0.22.tar.gz"
hset libsdlgfx depends "libsdl"

configure-libsdlgfx-local() {
        # autocrap wants a m4 directory , so we create it if not already done
	if [ ! -e m4 ]; then mkdir m4; fi
	rm -f configure
	configure-generic-local \
		--disable-mmx --without-x --disable-sdltest
}
configure-libsdlgfx() {
	export SDL_CONFIG="$STAGING_TOOLS"/bin/sdl-config
	configure configure-libsdlgfx-local
}

deploy-libsdlgfx(){
	# we use ROOTFS_KEEPERS to tell minifs to keep stuff, it will look in standard install directories for the keepers, so they
	# stay in the ROOTFS for final deployment into our .img file :)
	ROOTFS_KEEPERS+="libSDL_gfx.so:"
}

PACKAGES+=" gmenu2x"
hset gmenu2x url "git!git://projects.qi-hardware.com/gmenu2x.git#gmenu2x-git.tar.bz2"
hset gmenu2x depends "libsdl libsdlgfx libsdlimage libpng"
 
configure-gmenu2x() {
	export SDL_CONFIG="$STAGING_TOOLS"/bin/sdl-config
    export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic --without-x --disable-sdltest --enable-platform=gp2x
	# We're using the gp2x platform flag, not entirely sure how significant this is
	# but it's a closer target to the frame than anything else i think
	# eventually we'll have our own specific platform, we need to create a platform folder
	# for the gp2x otherwise the installer will fail, so we snarf the pandora one and copy it :D
	export LDFLAGS="$LDFLAGS_BASE"
	cp -rf data/platform/pandora data/platform/gp2x
}

deploy-gmenu2x-local() {
	cp -rf "$STAGING_USR"/share/gmenu2x/ "$ROOTFS"/usr/share/
    cp $(get_installed_binaries) "$ROOTFS"/usr/share/gmenu2x
    # hacky fix to create a script file, should probably create a patch that makes the file in conf/patches/
	echo "#!/bin/hush" > "$ROOTFS"/usr/sbin/gmenu2x
	echo "cd /usr/share/gmenu2x/" >> "$ROOTFS"/usr/sbin/gmenu2x
	echo "./gmenu2x &" >> "$ROOTFS"/usr/sbin/gmenu2x
	chmod a+wrx "$ROOTFS"/usr/sbin/gmenu2x
}

deploy-gmenu2x() {
    ROOTFS_KEEPERS+="libstdc++.so:"
    # the deploy command is part of minifs's logging system, I think any command you prepend 
    # with deploy will end up in the packages ._deploy_package.log file, useful when testing scripts to see what went wrong
	deploy deploy-gmenu2x-local
 }


deploy-e2fsprogs(){
	deploy deploy_binaries
}

PACKAGES+=" viewimage"
hset viewimage url "http://dl.dropbox.com/u/12747635/parrot_df3120/src/viewimage.tar.gz"
hset viewimage depends " libsdl libsdlimage libsdlgfx"

compile-viewimage(){
	make clean && make
}

deploy-viewimage(){
	deploy cp ./viewimage "$ROOTFS"/usr/bin
}
