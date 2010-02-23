#######################################################################
## dropbear
#######################################################################
PACKAGES="$PACKAGES dropbear"

configure-dropbear-nah() {
	configure ./configure --enable-static --disable-shared \
		--prefix="$ROOTFS" \
		--host=$TARGET_FULL_ARCH \
		--with-zlib="$STAGING"
}
install-dropbear() {
	log_install echo Done
}
deploy-dropbear() {
	deploy $MAKE install
	mkdir -p "$ROOTFS/etc/dropbear"
	if [ $TARGET_ARCH = "i386" ]; then	
		if [ ! -f "$BUILD"/dropbear_dss_host_key ]; then
			echo "#### generating new dropbear keys"
			"$ROOTFS"/bin/dropbearkey -t dss -f "$BUILD"/dropbear_dss_host_key
			"$ROOTFS"/bin/dropbearkey -t rsa -f "$BUILD"/dropbear_rsa_host_key
		fi
	fi
	cp "$BUILD"/dropbear_*_host_key "$ROOTFS"/etc/dropbear/	
}
