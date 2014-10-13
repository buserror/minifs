
PACKAGES+=" iproute2"
hset iproute2 url "http://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-3.15.0.tar.gz"

configure-iproute2() {
	configure-generic 
}

compile-iproute2() {
 cpwd=`pwd`
 compile $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS -I$cpwd/include" CONFIG_PREFIX="$ROOTFS" SUBDIRS="lib tc"
}

deploy-iproute2() {
	deploy cp tc/tc "$ROOTFS"/bin/
}


