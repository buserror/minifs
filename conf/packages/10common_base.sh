
#######################################################################
## zlib - http://www.zlib.net/
#######################################################################
PACKAGES+=" zlib"
hset zlib url "http://www.zlib.net/zlib-1.2.6.tar.gz"

configure-zlib() {
	configure ./configure \
		--prefix="/usr"
}

#######################################################################
## lzo - http://www.oberhumer.com/opensource/lzo/
#######################################################################
PACKAGES+=" lzo"
hset lzo url "http://www.oberhumer.com/opensource/lzo/download/lzo-2.04.tar.gz"
hset lzo depends "busybox"

#######################################################################
## e2fsprog - http://e2fsprogs.sourceforge.net/
#######################################################################
PACKAGES+=" e2fsprogs"
hset e2fsprogs url "http://heanet.dl.sourceforge.net/project/e2fsprogs/e2fsprogs/1.41.14/e2fsprogs-libs-1.41.14.tar.gz"
hset e2fsprogs depends "busybox"

configure-e2fsprogs() {
	save=$CFLAGS; CFLAGS+=" -fPIC"
	configure-generic \
		--disable-tls
	CFLAGS=$save
}

#######################################################################
## screen
#######################################################################
PACKAGES+=" screen"
hset screen url "http://ftp.gnu.org/gnu/screen/screen-4.0.3.tar.gz"
hset screen depends "busybox"

patch-screen() {
	rm -f configure
}

#######################################################################
## i2c-tools - http://www.lm-sensors.org/wiki/I2CTools
#######################################################################
PACKAGES+=" i2c"
hset i2c url "http://dl.lm-sensors.org/i2c-tools/releases/i2c-tools-3.0.3.tar.bz2"
hset i2c depends "busybox"

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
## libusb- http://sourceforge.net/projects/libusb/files/libusb-1.0/
#######################################################################
PACKAGES+=" libusb"
hset libusb url "http://downloads.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.8/libusb-1.0.8.tar.bz2"

PACKAGES+=" libusb-compat"
hset libusb-compat url "http://downloads.sourceforge.net/project/libusb/libusb-compat-0.1/libusb-compat-0.1.3/libusb-compat-0.1.3.tar.bz2"
hset libusb-compat depends "libusb"

# http://www.linuxfromscratch.org/blfs/view/cvs/general/usbutils.html
PACKAGES+=" usbutils"
hset usbutils url "http://downloads.sourceforge.net/project/linux-usb/usbutils/usbutils-0.86.tar.gz"
hset usbutils depends "libusb-compat busybox"

configure-usbutils() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-usbutils() {
	deploy cp "$STAGING_USR"/sbin/lsusb "$ROOTFS"/usr/bin/
	cp "$STAGING_USR"/share/usb.ids.gz "$ROOTFS"/usr/share/
}

#######################################################################
## libftdi - http://www.intra2net.com/en/developer/libftdi/
#######################################################################
PACKAGES+=" libftdi"
hset libftdi url "http://www.intra2net.com/en/developer/libftdi/download/libftdi-0.18.tar.gz"
hset libftdi depends "libusb-compat"

configure-libftdi() {
	configure-generic \
		--disable-libftdipp 
	# --with-async-mode # removed at 0.17
}

#######################################################################
## mtd_utils
#######################################################################
PACKAGES+=" mtd_utils"
hset mtd_utils url "http://git.infradead.org/mtd-utils.git/snapshot/a67747b7a314e685085b62e8239442ea54959dbc.tar.gz#mtd_utils.tgz"
hset mtd_utils depends "zlib lzo e2fsprogs"

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
## hotplug. works but needs udevtrigger, that means bloatware udev
#######################################################################

PACKAGES+=" udev"
hset udev url "http://www.kernel.org/pub/linux/utils/kernel/hotplug/udev-151.tar.bz2"
hset udev depends "busybox"

install-udev() {
	log_install echo Skipping udev install. yuck
}

PACKAGES+=" hotplug2"
hset hotplug2 url "http://isteve.bofh.cz/~isteve/hotplug2/downloads/hotplug2-0.9.tar.gz"
hset hotplug2 depends "busybox"

configure-hotplug2() {
	configure echo Done
}

install-hotplug2() {
	export INSTALL_USR=1
	install-generic
	unset INSTALL_USR
}
