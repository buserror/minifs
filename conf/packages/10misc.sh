
PACKAGES+=" libtalloc"
hset libtalloc url "http://samba.org/ftp/talloc/talloc-2.0.1.tar.gz"

PACKAGES+=" libexpat"
hset libexpat url "http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz"

PACKAGES+=" libreadline"
hset libreadline url "ftp://ftp.gnu.org/gnu/readline/readline-6.1.tar.gz"

PACKAGES+=" libncurses"
hset libncurses url "http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.7.tar.gz"

PACKAGES+=" libnetsnmp"
hset libnetsnmp url "http://downloads.sourceforge.net/project/net-snmp/net-snmp/5.5/net-snmp-5.5.tar.gz#netsnmp-5.5.tgz"

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
hset libiconv url "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"

configure-libiconv() {
	configure-generic \
		--disable-rpath \
		--disable-nls
}

PACKAGES+=" libxml2"
hset libxml2 url "ftp://xmlsoft.org/libxml2/libxml2-2.7.6.tar.gz"

configure-libxml2() {
	configure-generic \
		--without-python
}

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

PACKAGES+=" libgettext"
hset libgettext url "http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.1.1.tar.gz"

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


#######################################################################
## GNU/TLS bits
#######################################################################

PACKAGES+=" libgpg-error"
hset libgpg-error url "ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.7.tar.bz2"

PACKAGES+=" libgcrypt"
hset libgcrypt url "ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.4.5.tar.bz2"
hset libgcrypt depends "libgpg-error"

configure-libgcrypt() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic --disable-asm
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" gnutls"
hset gnutls url "http://ftp.gnu.org/pub/gnu/gnutls/gnutls-2.8.6.tar.bz2"
hset gnutls depends "libgcrypt"

configure-gnutls() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic \
		--with-libgcrypt-prefix="$STAGING_USR" \
		--with-libreadline-prefix="$STAGING_USR" \
		--disable-rpath
	export LDFLAGS="$LDFLAGS_BASE"
}

#######################################################################
## OpenSSL
#######################################################################
PACKAGES+=" openssl"
hset openssl url "http://www.openssl.org/source/openssl-0.9.8o.tar.gz"

configure-openssl() {
	configure ./config --prefix=/usr --install_prefix="$STAGING" no-asm shared
}
compile-openssl() {
	compile make \
		CC=$GCC AR="${CROSS}-ar r" RANLIB=${CROSS}-ranlib \
		CFLAG="$TARGET_CFLAGS"
}

#######################################################################
## Netscape security API
#######################################################################
PACKAGES+=" libnspr"
hset libnspr url "https://ftp.mozilla.org/pub/mozilla.org/nspr/releases/v4.8.4/src/nspr-4.8.4.tar.gz"
hset libnspr dir "libnspr/mozilla/nsprpub"
hset libnspr phases "none"

PACKAGES+=" libnss"
hset libnss url "https://ftp.mozilla.org/pub/mozilla.org/security/nss/releases/NSS_3_12_3_RTM/src/nss-3.12.3.tar.bz2"
hset libnss depends "libnspr"

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
	path=$(echo mozilla/dist/Linux*$TARGET_KERNEL_ARCH*)
	echo mozicrap = $path
	pushd "$path"/lib
	for lib in libssl3.so libnss3.so libnssutil3.so libplc4.so libplds4.so libnspr4.so libsmime3.so; do
		fn=$(readlink -f $lib)
		echo lib $fn
		cp "$fn" "$STAGING_USR"/lib/
	done
	popd
	echo Done
}

install-libnss() {
	log_install install-libnss-local
}

#######################################################################
## curl
#######################################################################
PACKAGES+=" libcurl"
hset libcurl url "http://curl.haxx.se/download/curl-7.21.2.tar.bz2"

PACKAGES+=" curl"
hset curl url "none"
hset curl depends "libcurl busybox"
hset curl dir "libcurl"
hset curl phases "deploy"

configure-libcurl() {
	local extras="--with-random=/dev/urandom "	
	export LDFLAGS="$LDFLAGS_RLINK"
	if [ -d ../openssl ]; then 
		extras+="--with-ssl ";
	fi
	if [ -d ../gnutls ]; then 
		extras+="--with-gnutls "
		LDFLAGS+=" -lgcrypt -lgpg-error"
	fi
	echo "ac_cv_path_PKGCONFIG=$BUILD/staging-tools/bin/pkg-config
ac_cv_lib_gnutls_gnutls_check_version=yes" >minifs.cache
	configure-generic --cache=minifs.cache $extras
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-curl() {
	cp "$STAGING_USR"/bin/curl "$ROOTFS"/usr/bin/
}

PACKAGES+=" rsync"
hset rsync url "http://samba.anu.edu.au/ftp/rsync/src/rsync-3.0.7.tar.gz"
hset rsync depends "busybox"

deploy-rsync() {
	deploy cp "$STAGING_USR"/bin/rsync "$ROOTFS"/bin/
}

PACKAGES+=" picocom"
hset picocom url "http://picocom.googlecode.com/files/picocom-1.6.tar.gz"
hset picocom depends "busybox"

compile-picocom() {
	compile make CFLAGS="$CFLAGS"
}

install-picocom() {
	log_install cp picocom "$STAGING_USR"/bin/
}

deploy-picocom() {
	deploy cp "$STAGING_USR"/bin/picocom "$ROOTFS"/bin/
}
