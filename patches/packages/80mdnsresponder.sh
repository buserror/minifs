#######################################################################
## mDSNResponder
#######################################################################
PACKAGES="$PACKAGES mDSNResponder"
hset url mDSNResponder 		"http://www.opensource.apple.com/darwinsource/tarballs/other/mDNSResponder-107.6.tar.gz"

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
