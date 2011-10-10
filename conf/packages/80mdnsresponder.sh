
#######################################################################
## mDNSResponder
#######################################################################
PACKAGES+=" mDNSResponder"
#V="107.6"
V="320.5.1"
hset mDNSResponder version $V
hset mDNSResponder url "http://www.opensource.apple.com/darwinsource/tarballs/other/mDNSResponder-$V.tar.gz"
hset mDNSResponder depends "busybox"

configure-mDNSResponder() {
	configure echo Done
}

compile-mDNSResponder-local() {
	$MAKE -C mDNSPosix \
		libdns_sd \
		os=linux CC="ccfix $TARGET_FULL_ARCH-gcc" STRIP="$TARGET_FULL_ARCH-strip" \
		LD="$TARGET_FULL_ARCH-gcc" \
		CFLAGS_CROSS="-Os $TARGET_CFLAGS -I$STAGING/include" \
		LINKOPTS="$LDFLAGS -shared -Wl,-soname,libdns_sd.so" &&
	$MAKE -C mDNSPosix \
		SAResponder  Daemon \
		os=linux CC="ccfix $TARGET_FULL_ARCH-gcc" STRIP="$TARGET_FULL_ARCH-strip" \
		LD="$TARGET_FULL_ARCH-ld" \
		CFLAGS_CROSS="-Os $TARGET_CFLAGS -I$STAGING/include" \
		LINKOPTS="$LDFLAGS"
}
compile-mDNSResponder() {
	compile compile-mDNSResponder-local
}

install-mDNSResponder-local() {
	cp mDNSPosix/build/prod/mDNSResponderPosix "$STAGING_USR"/bin/
	cp mDNSPosix/build/prod/mdnsd "$STAGING_USR"/bin/
	cp mDNSPosix/build/prod/libdns_sd.so "$STAGING_USR"/lib/
	cp mDNSShared/dns_sd.h "$STAGING_USR"/include/
}

install-mDNSResponder() {
	log_install install-mDNSResponder-local
}

deploy-mDNSResponder() {
	deploy cp \
		"$STAGING_USR"/bin/mDNSResponderPosix \
		"$STAGING_USR"/bin/mdnsd \
		"$ROOTFS"/usr/bin/
}
