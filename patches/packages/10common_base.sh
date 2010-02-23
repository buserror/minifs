

#######################################################################
## zlib
#######################################################################
PACKAGES="$PACKAGES zlib"
hset url zlib "http://www.zlib.net/zlib-1.2.3.tar.gz" 

configure-zlib() {
	configure ./configure \
		--prefix="$STAGING"
}

#######################################################################
## lzo
#######################################################################
PACKAGES="$PACKAGES lzo"
hset url lzo "http://www.oberhumer.com/opensource/lzo/download/lzo-2.03.tar.gz"


#######################################################################
## e2fsprog
#######################################################################
PACKAGES="$PACKAGES e2fsprogs"
hset url e2fsprogs	"http://heanet.dl.sourceforge.net/project/e2fsprogs/e2fsprogs/1.41.9/e2fsprogs-libs-1.41.9.tar.gz"

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
hset url screen "http://ftp.gnu.org/gnu/screen/screen-4.0.3.tar.gz" 

#######################################################################
## i2c-tools
#######################################################################
PACKAGES="$PACKAGES i2c"
hset url i2c "http://dl.lm-sensors.org/i2c-tools/releases/i2c-tools-3.0.2.tar.bz2"

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
hset url libusb "http://kent.dl.sourceforge.net/project/libusb/libusb-0.1%20%28LEGACY%29/0.1.12/libusb-0.1.12.tar.gz"

#######################################################################
## libftdi
#######################################################################
PACKAGES="$PACKAGES libftdi"
hset url libftdi "http://www.intra2net.com/en/developer/libftdi/download/libftdi-0.16.tar.gz"

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
hset url mtd_utils "http://git.infradead.org/mtd-utils.git/snapshot/a67747b7a314e685085b62e8239442ea54959dbc.tar.gz#mtd_utils.tgz"

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

#######################################################################
## Jpeg
#######################################################################
PACKAGES="$PACKAGES libjpeg"
hset url libjpeg	"http://www.ijg.org/files/jpegsrc.v7.tar.gz" 

