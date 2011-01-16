
PACKAGES+=" fbvncslave"
hset fbvncslave url "none"
hset fbvncslave dir "."
hset fbvncslave depends "libvncserver"

configure-fbvncslave() {
	configure echo Done
}
compile-fbvncslave() {
	compile echo Done
}
install-fbvncslave() {
	log_install $GCC $CPPFLAGS $CFLAGS -std=gnu99  \
		-Wall \
		"$CONFIG"/fbvncslave.c \
		-o "$STAGING_USR"/bin/fbvncslave $LDFLAGS_RLINK \
		-lvncclient -ljpeg -lz
}
deploy-fbvncslave() {
	deploy cp "$STAGING_USR"/bin/fbvncslave "$ROOTFS"/usr/bin/
}

PACKAGES+=" plftool"
hset plftool url "git!http://oomz.net/git/df3120/plftool.git#plftool-df3120-git.tar.bz2"
hset plftool depends "uboot"

configure-plftool() {
	configure echo Done
}
compile-plftool-local() {
	( 	export PATH="$BASE_PATH"
	unset CC CXX GCC LD CFLAGS CXXFLAGS CPPFLAGS LDFLAGS ACLOCAL ; 
	unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR LD_LIBRARY_PATH ;
	make
	)
}
compile-plftool() {
	compile compile-plftool-local
}
install-plftool() {
	log_install echo Done
}
deploy-plftool() {
	deploy ./pack_uboot.sh df3120 ../uboot/u-boot.bin ../parrotDF3120.plf
}
