

#######################################################################
## zlib
#######################################################################
PACKAGES="$PACKAGES zlib"

configure-zlib() {
	configure ./configure \
		--prefix="$STAGING"
}

#######################################################################
## lzo
#######################################################################
PACKAGES="$PACKAGES lzo"


#######################################################################
## e2fsprog
#######################################################################
PACKAGES="$PACKAGES e2fsprogs"

configure-e2fsprogs() {
	configure ./configure \
		--host=$TARGET_FULL_ARCH \
		--prefix="$STAGING" \
		--disable-tls
}

#######################################################################
## screen
#######################################################################
PACKAGES="$PACKAGES screen"

#######################################################################
## i2c-tools
#######################################################################
PACKAGES="$PACKAGES i2c"

configure-i2c() {
	configure echo Done
}
compile-i2c() {
	compile $MAKE CC=$GCC LDFLAGS="$LDFLAGS -static"
}
install() {
	log_install echo Done
}
deploy-i2c() {
	deploy cp ./tools/i2c{detect,dump,get,set} "$ROOTFS/bin/"
}

#######################################################################
## libusb
#######################################################################
PACKAGES="$PACKAGES libusb"

#######################################################################
## libftdi
#######################################################################
PACKAGES="$PACKAGES libftdi"

configure-libftdi() {
	configure  ./configure \
		--prefix="$STAGING" \
		--host=$TARGET_FULL_ARCH \
		--disable-libftdipp --with-async-mode
}

#######################################################################
## mtd_utils
#######################################################################
PACKAGES="$PACKAGES mtd_utils"

configure-mtd_utils() {
	configure echo Done
}
compile-mtd_utils() {
	compile $MAKE CC=$GCC \
		CFLAGS="$TARGET_CFLAGS -I$STAGING/include -DWITHOUT_XATTR" \
		LDFLAGS="$LDFLAGS -static"
}
install-mtd_utils() {
	log_install echo Done
}
deploy-mtd_utils() {
	deploy cp nandwrite mtd_debug  "$ROOTFS/bin/"
}

