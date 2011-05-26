
PACKAGES+=" syslinux"
hset syslinux url "http://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-4.04.tar.bz2"
#hset syslinux depends "linux-modules"
hset syslinux phases "deploy"

compile-syslinux() {
	compile-generic \
		CC="$CC" LD="$LD" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS_RLINK"
}

install-syslinux() {
	install-generic \
		CC="$CC" LD="$LD" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS_RLINK"
}

deploy-syslinux() {
	deploy echo Done
}
