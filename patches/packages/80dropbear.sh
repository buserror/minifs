#######################################################################
## dropbear
#######################################################################
PACKAGES+=" dropbear"

hset url dropbear	"http://matt.ucc.asn.au/dropbear/releases/dropbear-0.52.tar.bz2" 
hset prefix dropbear "/"
hset depends dropbear "busybox"

configure-dropbear() {
	configure-generic \
		--enable-static --disable-shared \
		--with-zlib="$STAGING"/lib \
		LDFLAGS="-static"
}
compile-dropbear() {
	compile $MAKE -j8 PROGRAMS="dropbear dropbearkey scp" STATIC=1 SCPPROGRESS=1
}
install-dropbear() {
	install echo Done
}

deploy-dropbear() {
	deploy cp dropbear dropbearkey scp \
		"$ROOTFS"/bin/
	mkdir -p "$ROOTFS/etc/dropbear"
	if [ $TARGET_ARCH = "i386" ]; then	
		if [ ! -f "$BUILD"/dropbear_dss_host_key ]; then
			( echo "#### generating new dropbear keys" ; \
			./dropbearkey -t dss -f "$BUILD"/dropbear_dss_host_key ; \
			./dropbearkey -t rsa -f "$BUILD"/dropbear_rsa_host_key ) >>"$LOGFILE"
		fi
	fi
	cp "$BUILD"/dropbear_*_host_key "$ROOTFS"/etc/dropbear/	
}
