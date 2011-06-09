#######################################################################
## dropbear
#######################################################################
PACKAGES+=" dropbear"

V="0.53.1"
hset dropbear version $V
hset dropbear url "http://matt.ucc.asn.au/dropbear/releases/dropbear-$V.tar.bz2"
hset dropbear prefix "/"
hset dropbear depends "busybox"

configure-dropbear() {
	if [ "$TARGET_SHARED" -eq 0 ]; then
		configure-generic \
			--enable-static --disable-shared LDFLAGS=-static 
	else
		configure-generic
	fi
}

compile-dropbear() {
	if [ "$TARGET_SHARED" -eq 0 ]; then
		compile $MAKE -j8 PROGRAMS="dropbear dropbearkey scp" STATIC=1 SCPPROGRESS=1
	else
		compile $MAKE -j8 PROGRAMS="dropbear dropbearkey scp" SCPPROGRESS=1
	fi
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
