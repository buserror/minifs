

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
		--prefix="$STAGING" \
		--host=$TARGET_FULL_ARCH \
		--disable-tls \
		--enable-static --disable-shared
}

#######################################################################
## screen
#######################################################################
PACKAGES="$PACKAGES screen"

configure-screen() {
	configure ./configure \
		--prefix="$ROOTFS" \
		--host=$TARGET_FULL_ARCH \
		 --enable-static --disable-shared
}

#######################################################################
## i2c-tools
#######################################################################
PACKAGES="$PACKAGES i2c"

configure-i2c() {
	configure echo Done
}
compile-i2c() {
	compile $MAKE CC=$GCC
}
install-i2c() {
	install cp ./tools/i2c{detect,dump,get,set} "$ROOTFS/bin/"
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
		--enable-static --disable-shared \
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
		CFLAGS="$TARGET_CFLAGS -I$STAGING/include -DWITHOUT_XATTR"
}
install-mtd_utils() {
	install cp nandwrite mtd_debug  "$ROOTFS/bin/"
}

