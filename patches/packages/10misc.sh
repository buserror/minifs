#######################################################################
## curl
#######################################################################
PACKAGES+=" curl"
hset url curl "http://curl.haxx.se/download/curl-7.20.0.tar.bz2"
hset depends curl "busybox"

PACKAGES+=" libexpat"
hset url libexpat "http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz"

PACKAGES+=" libreadline"
hset url libreadline "ftp://ftp.gnu.org/gnu/readline/readline-6.1.tar.gz"

PACKAGES+=" libnetsnmp"
hset url libnetsnmp "http://downloads.sourceforge.net/project/net-snmp/net-snmp/5.5/net-snmp-5.5.tar.gz#netsnmp-5.5.tgz"

configure-libnetsnmp() {
	configure-generic \
		--with-defaults \
		--with-transports="UDP" \
		--disable-embedded-perl \
		--disable-mib-loading \
		--disable-scripts \
		--disable-manuals \
		--disable-des \
		--disable-privacy \
		--without-perl-modules \
		--without-python-modules
}

# this is only needed for uclibc! otherwise eglibc has one already
PACKAGES+=" libiconv"
hset url libiconv "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"

configure-libiconv() {
	configure-generic \
		--disable-nls
}


PACKAGES+=" libgettext"
hset url libgettext "http://ftp.gnu.org/pub/gnu/gettext/gettext-0.17.tar.gz"

configure-libgettext() {
	configure-generic \
		--without-lispdir \
                 --disable-csharp \
                 --disable-libasprintf \
                 --disable-java \
                 --disable-native-java \
                 --disable-openmp \
                 --with-included-glib \
                 --without-emacs
}

PACKAGES+=" libxml2"
hset url libxml2 "ftp://xmlsoft.org/libxml2/libxml2-2.7.6.tar.gz"

install-libxml2() {
	install-generic
	# fix that script
	if [ -f "$STAGING_USR"/lib/xml2Conf.sh ]; then
		sed -i \
			-e "s|I/usr|I$STAGING_USR|g" \
			-e "s|L/usr|L$STAGING_USR|g" \
				"$STAGING_USR"/lib/xml2Conf.sh
	fi
}

#######################################################################
## OpenSSL
#######################################################################
PACKAGES+=" openssl"
hset url openssl "http://www.openssl.org/source/openssl-0.9.8m.tar.gz"

configure-openssl() {
	configure ./config --prefix=/usr --install_prefix="$STAGING" no-asm shared
}
compile-openssl() {
	compile make \
		CC=$GCC AR="${CROSS}-ar r" RANLIB=${CROSS}-ranlib \
		CFLAG="$TARGET_CFLAGS"
}

PACKAGES+=" libnspr"
hset url libnspr "https://ftp.mozilla.org/pub/mozilla.org/nspr/releases/v4.8.4/src/nspr-4.8.4.tar.gz"
hset dir libnspr "libnspr/mozilla/nsprpub"
hset phases libnspr "none"

PACKAGES+=" libnss"
hset url libnss "https://ftp.mozilla.org/pub/mozilla.org/security/nss/releases/NSS_3_12_3_RTM/src/nss-3.12.3.tar.bz2"
hset depends libnss "libnspr"

configure-libnss() {
	rm -f mozilla/nsprpub
	ln -s ../../libnspr/mozilla/nsprpub mozilla/nsprpub
	configure echo Done
}
compile-libnss() {
#		SOURCE_MD_DIR=$(DISTDIR) 
	compile make -C mozilla/security/nss \
		nss_build_all \
		MOZILLA_CLIENT=1 \
		NSPR_CONFIGURE_OPTS="--prefix=/usr --host=$TARGET_FULL_ARCH" \
		BUILD_OPT=1 \
		NS_USE_GCC=1 \
		OPTIMIZER="$TARGET_CFLAGS" \
		NSS_USE_SYSTEM_SQLITE=1 \
		NSS_ENABLE_ECC=1 
}

# this hack is there only to copy the libs we need for the flash player to link
install-libnss-local() {
	
	echo Done
}

install-libnss() {
	log_install install-libnss-local
}

