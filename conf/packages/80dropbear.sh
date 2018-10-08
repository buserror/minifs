#######################################################################
## dropbear
#######################################################################
PACKAGES+=" dropbear"

V="2017.75"
hset dropbear version $V
hset dropbear url "http://matt.ucc.asn.au/dropbear/releases/dropbear-$V.tar.bz2"
hset dropbear prefix "/"
hset dropbear depends "busybox zlib"
hset dropbear optional "pam"

configure-dropbear() {
	if [ "$TARGET_SHARED" -eq 0 ]; then
		configure-generic \
			--enable-static --disable-shared LDFLAGS=-static --enable-pam
	else
		configure-generic --enable-pam
	fi
}

compile-dropbear() {
	if [ "$TARGET_SHARED" -eq 0 ]; then
		compile $MAKE -j8 PROGRAMS="dropbear dropbearkey scp dbclient" STATIC=1 SCPPROGRESS=1
	else
		compile $MAKE -j8 PROGRAMS="dropbear dropbearkey scp dbclient" SCPPROGRESS=1
	fi
}

install-dropbear() {
	install echo Done
}

deploy-dropbear-local() {
	cp dropbear dropbearkey scp dbclient \
		"$ROOTFS"/bin/
	mkdir -p "$ROOTFS/etc/dropbear"
	if [ ! -f "$BUILD"/dropbear_dss_host_key ]; then
		echo -n "#### generating new dropbear keys : "
		{
			qemu-$TARGET_ARCH -L $ROOTFS ./dropbearkey -t dss -f "$BUILD"/dropbear_dss_host_key
			qemu-$TARGET_ARCH -L $ROOTFS ./dropbearkey -t rsa -f "$BUILD"/dropbear_rsa_host_key
			echo " done"
		} || echo " FAILED"
	fi

	if [ -f "$BUILD"/dropbear_dss_host_key ]; then
		cp "$BUILD"/dropbear_*_host_key "$ROOTFS"/etc/dropbear/
	fi
	mkdir -p "$ROOTFS"/var/log &&
		touch "$ROOTFS"/var/log/lastlog "$ROOTFS"/var/log/wtmp
}

deploy-dropbear() {
	deploy 	deploy-dropbear-local
}
