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
	compile $MAKE os=linux CC="$GCC" SAResponder \
		CFLAGS_CROSS="-Os $TARGET_CFLAGS -I$STAGING/include" \
		LINKOPTS="$LDFLAGS"
}
install-mDSNResponder() {
	log_install echo Done
}
deploy-mDSNResponder() {
	deploy cp build/prod/mDNSResponderPosix  "$ROOTFS/bin/"
}
