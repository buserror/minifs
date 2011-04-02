#######################################################################
## mDSNResponder
#######################################################################
PACKAGES+=" mDSNResponder"
V="107.6"
hset mDSNResponder version $V
hset mDSNResponder url "http://www.opensource.apple.com/darwinsource/tarballs/other/mDNSResponder-$V.tar.gz"
hset mDSNResponder depends "busybox"

configure-mDSNResponder() {
	configure echo Done
}

compile-mDSNResponder() {
	compile $MAKE -C mDNSPosix \
		os=linux CC="$GCC" SAResponder \
		CFLAGS_CROSS="-Os $TARGET_CFLAGS -I$STAGING/include" \
		LINKOPTS="$LDFLAGS"
}

install-mDSNResponder() {
	log_install cp mDNSPosix/build/prod/mDNSResponderPosix "$STAGING_USR"/bin/
}

deploy-mDSNResponder() {
	deploy cp "$STAGING_USR"/bin/mDNSResponderPosix "$ROOTFS"/usr/bin/
}
