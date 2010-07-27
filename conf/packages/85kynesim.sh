
PACKAGES+=" module-kbus"
hset module-kbus url "svn!http://kbus.googlecode.com/svn/#kbus-svn.tar.bz2"
hset module-kbus depends "linux-modules"

configure-module-kbus() {
	configure echo Done
}
compile-module-kbus() {
	compile-generic \
		O="$BUILD"/linux-obj \
		KERNELDIR="$BUILD"/linux-obj \
		CROSS_COMPILE="$TARGET_FULL_ARCH"-
}

install-module-kbus-local() {
	set -x
	mkdir -p "$STAGING_USR"/include/kbus
	cp kbus/kbus_defns.h "$STAGING_USR"/include/kbus/
	cp libkbus/kbus.h "$STAGING_USR"/include/kbus/
	cp "$BUILD"/linux-obj/kbus/kbus.ko \
		"$KERNEL"/lib/modules/$VERSION_linux/kernel/
	cp utils/kmsg "$STAGING_USR"/bin/
	set +x
}

install-module-kbus() {
	log_install install-module-kbus-local
}
