
PACKAGES+=" libpcap"
hset libpcap url "http://www.tcpdump.org/release/libpcap-1.3.0.tar.gz"
hset libpcap optional "pfring"

configure-libpcap() {
	configure-generic --with-pcap=linux
}

PACKAGES+=" tcpdump"
hset tcpdump url "http://www.tcpdump.org/release/tcpdump-4.3.0.tar.gz"
hset tcpdump depends "libpcap"

configure-tcpdump() {
	echo ac_cv_linux_vers=3 >config.cache
	configure-generic --cache-file=config.cache
}

deploy-tcpdump() {
	deploy cp tcpdump "$ROOTFS"/bin/
}


##############################################
#
# Turn out pfring uses stupid binary modules
# in the library, with hard coded architecture
# etc... so it's completely useless.
#
##############################################
PACKAGES+=" pfring"
hset pfring url "http://downloads.sourceforge.net/project/ntop/PF_RING/PF_RING-5.4.5.tar.gz"
hset pfring targets "pfring-kernel pfring-lib"

hset pfring-kernel dir "pfring/kernel"

PACKAGES+=" pfring-kernel"

# this patch is in the newer 5.4.6 version...
patch-pfring() {
	sed -i -e "s|ec_ptr|ax25_ptr|" \
		kernel/linux/pf_ring.h
}

install-pfring-kernel() {
	log_install $MAKE -C "$BUILD"/linux-obj \
		ARCH=$TARGET_KERNEL_ARCH  \
		CROSS_COMPILE="${CROSS}-" \
		SUBDIRS=$(pwd) \
		INSTALL_HDR_PATH="$KERNEL" INSTALL_MOD_PATH="$KERNEL" \
		install modules_install
}

compile-pfring-kernel() {
	compile-generic -C "$BUILD"/linux-obj \
		ARCH=$TARGET_KERNEL_ARCH  \
		CROSS_COMPILE="${CROSS}-" \
		SUBDIRS=$(pwd) \
		modules
}

hset pfring-lib dir "pfring/userland/lib"
hset pfring-lib depends "pfring-kernel"

compile-pfring-lib() {
	compile-generic \
		CROSS_COMPILE="${CROSS}-" 
}
install-pfring-lib() {
	log_install \
		CROSS_COMPILE="${CROSS}-" \
		install
}

PACKAGES+=" pfring-lib"
 
hset pfring-tools dir "pfring/userland/examples"
hset pfring-tools depends "pfring-lib"

