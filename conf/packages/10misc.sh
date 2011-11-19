
# 110906 Updated 2.0.6 http://samba.org/ftp/talloc/
PACKAGES+=" libtalloc"
hset libtalloc url "http://samba.org/ftp/talloc/talloc-2.0.6.tar.gz"

patch-libtalloc() {
	cp "$PATCHES"/libtalloc-make/* .
}

# 110906 No changes http://expat.sourceforge.net/
PACKAGES+=" libexpat"
hset libexpat url "http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz"

# 110906 Updated 6.2 http://cnswww.cns.cwru.edu/php/chet/readline/rltop.html
PACKAGES+=" libreadline"
hset libreadline url "ftp://ftp.gnu.org/gnu/readline/readline-6.2.tar.gz"

# 110906 Updated 5.9 http://www.gnu.org/software/ncurses/
PACKAGES+=" libncurses"
hset libncurses url "http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz"
hset libncurses configscript "ncurses5-config"

deploy-libncurses() {
	mkdir -p "$ROOTFS"/usr/share/
	deploy cp -ra "$STAGING_USR"/share/terminfo "$ROOTFS"/usr/share/
}
# 111013 Updated 2.0.15 http://www.monkey.org/~provos/libevent/
PACKAGES+=" libevent"
hset libevent url "https://github.com/downloads/libevent/libevent/libevent-2.0.15-stable.tar.gz"

# 110906 Updated 1.5 http://tmux.sourceforge.net/
PACKAGES+=" tmux"
hset tmux url "http://downloads.sourceforge.net/project/tmux/tmux/tmux-1.5/tmux-1.5.tar.gz"
hset tmux depends " libevent libncurses"

deploy-tmux() {
	deploy deploy_binaries
}

# 110906 No changes
PACKAGES+=" libpopt"
hset libpopt url "http://ftp.debian.org/debian/pool/main/p/popt/popt_1.16.orig.tar.gz"

# 110906 No changes http://ftp.debian.org/debian/pool/main/p/pump/
PACKAGES+=" pump"
hset pump url "http://ftp.debian.org/debian/pool/main/p/pump/pump_0.8.24.orig.tar.gz"
hset pump depends "libpopt"

patch-pump() {
	cat debian/patches/*.patch | patch --merge -p1
}
compile-pump() {
	compile-generic \
		DEB_CFLAGS="$CFLAGS -DUDEB=1" \
		LDFLAGS="$LDFLAGS_RLINK" \
		pump
}
install-pump() {
	mkdir -p "$STAGING_USR"/sbin
	log_install cp pump "$STAGING_USR"/sbin/
}
deploy-pump() {
	deploy cp "$STAGING_USR"/sbin/pump "$ROOTFS"/sbin/
}

# this is only needed for uclibc! otherwise eglibc has one already
PACKAGES+=" libiconv"
if [ "$CONFIG_UCLIBC" != "" ]; then
	# echo UCLIBC build - add libiconv
	hset libiconv url "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"
fi

configure-libiconv() {
	configure-generic \
		--disable-rpath \
		--disable-nls
}

# 110906 Updated 2.7.8 ftp://xmlsoft.org/libxml2/
PACKAGES+=" libxml2"
hset libxml2 url "ftp://xmlsoft.org/libxml2/libxml2-2.7.8.tar.gz"
hset libxml2 configscript "xml2-config"

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

# 110906 No Changes
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
                 --without-emacs \
                 --with-libncurses-prefix="$STAGING_USR" \
                 --with-libxml2-prefix="$STAGING_USR"
	CFLAGS="$TARGET_CFLAGS"
}
 
 
# 110906 Updated 3.6.23.1 http://www.sqlite.org/ -- 3.7 is all borken and .zip
PACKAGES+=" sqlite3"
V="3.6.23.1"
hset sqlite3 version $V
hset sqlite3 url "http://www.sqlite.org/sqlite-$V.tar.gz"

#######################################################################
## GNU/TLS bits
#######################################################################

# 110906 Updated 1.9 ftp://ftp.gnupg.org/gcrypt/libgpg-error/
PACKAGES+=" libgpg-error"
hset libgpg-error url "ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.9.tar.bz2"
hset libgpg-error depends "libiconv libgettext"
hset libgpg-error configscript "gpg-error-config"

# 110906 Updated 1.5.0 http://www.gnupg.org/download/index.html#libgcrypt
PACKAGES+=" libgcrypt"
hset libgcrypt url "ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.0.tar.bz2"
hset libgcrypt depends "libgpg-error"
hset libgcrypt configscript "libgcrypt-config"

configure-libgcrypt() {
	export LDFLAGS="$LDFLAGS_RLINK -lgpg-error"
	configure-generic --disable-asm --disable-tests \
		--with-gpg-error-prefix="$STAGING_USR"
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libgmp"
hset libgmp url "ftp://ftp.gmplib.org/pub/gmp-5.0.2/gmp-5.0.2.tar.bz2"

PACKAGES+=" libnettle"
hset libnettle url "http://www.lysator.liu.se/~nisse/archive/nettle-2.4.tar.gz"
hset libnettle depends "libgmp"

configure-libnettle() {
	configure-generic --disable-openssl --enable-shared
}

PACKAGES+=" libp11-kit"
hset libp11-kit url "http://p11-glue.freedesktop.org/releases/p11-kit-0.5.tar.gz"

# 110906 Updated 2.12.10 http://ftp.gnu.org/gnu/gnutls/
#        Now requires libnettle, no libgcrypt
PACKAGES+=" gnutls"
hset gnutls url "http://ftp.gnu.org/pub/gnu/gnutls/gnutls-2.12.10.tar.bz2"
hset gnutls depends "libgcrypt libp11-kit"

configure-gnutls() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic \
		--with-libgcrypt \
		--with-libgcrypt-prefix="$STAGING_USR" \
		--with-libreadline-prefix="$STAGING_USR" \
		--with-included-libtasn1 \
		--disable-rpath
	export LDFLAGS="$LDFLAGS_BASE"
}

#######################################################################
## OpenSSL - http://www.openssl.org/
#######################################################################
# 110906 Updated 1.0.0e
PACKAGES+=" openssl"
hset openssl url "http://www.openssl.org/source/openssl-1.0.0e.tar.gz"
hset openssl targets "openssl openssl-bin"
hset openssl deploy false
hset openssl config "linux-generic32"

configure-openssl() {
	local conf=$(hget openssl config)
	configure ./Configure --prefix=/usr --install_prefix="$STAGING" no-asm shared $conf
}
compile-openssl() {
	local base=$(awk '/^CFLAG= / {print substr($0,8);}' Makefile)
	compile $MAKE \
		CC="ccfix $TARGET_FULL_ARCH-gcc" \
		AR="ccfix $TARGET_FULL_ARCH-ar r" \
		RANLIB="$TARGET_FULL_ARCH-ranlib" \
		CFLAG="$base $TARGET_CFLAGS"
}
deploy-openssl() {
	deploy deploy_binaries
}

#######################################################################
## Netscape security API
#######################################################################
# 110906 Checked
PACKAGES+=" libnss"
hset libnss url "https://ftp.mozilla.org/pub/mozilla.org/security/nss/releases/NSS_3_12_11_RTM/src/nss-3.12.11-with-nspr-4.8.9.tar.gz"
hset libnss depends "sqlite3"

configure-libnss() {
	configure echo Done
}
compile-libnss() {
#		SOURCE_MD_DIR=$(DISTDIR) 
	local extra=""
	local build=""
	local nspr=""
	if [ "$TARGET_ARCH" = "x86_64" ]; then
		extras="-DNS_PTR_GT_32=1"
		build="USE_64=1"
		nspr="--enable-64bit"
	fi
	
	compile make -C mozilla/security/nss \
		nss_build_all \
		MOZILLA_CLIENT=1 \
		CC="$GCC" \
		NSPR_CONFIGURE_OPTS="--prefix=/usr --host=$TARGET_FULL_ARCH $nspr" \
		BUILD_OPT=1 \
		NS_USE_GCC=1 \
		OPTIMIZER="$CPPFLAGS $TARGET_CFLAGS $extras" \
		NSS_ENABLE_ECC=1 \
		NSS_USE_SYSTEM_SQLITE=1 \
		SQLITE_LIB_NAME=sqlite3 \
		USE_SYSTEM_ZLIB=1 \
		USE_PTHREADS=1 \
		ARCHFLAG="$LDFLAGS_RLINK" \
		$build
}

# this hack is there only to copy the libs we need for the flash player to link
install-libnss-local() {
	path=$(echo mozilla/dist/Linux*$TARGET_KERNEL_ARCH*)
	echo mozicrap = $path
	(
	cd "$path"/lib
	for lib in *.so; do
		fn=$(readlink -f $lib)
		echo lib open "$STAGING_USR"/lib/$(basename $fn)
		cp "$fn" "$STAGING_USR"/lib/
	done
	) >._dist_$PACKAGE.log
	echo Done
}

install-libnss() {
	log_install install-libnss-local
}

#######################################################################
## curl - http://curl.haxx.se/
#######################################################################
# 110906 Updated 7.21.7
PACKAGES+=" libcurl"
hset libcurl url "http://curl.haxx.se/download/curl-7.21.7.tar.bz2"

PACKAGES+=" curl"
hset curl url "none"
hset curl depends "libcurl busybox"
hset curl dir "libcurl"
hset curl phases "deploy"
hset curl configscript "curl-config"

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

# 110906 Checked http://samba.anu.edu.au/rsync/
PACKAGES+=" rsync"
hset rsync url "http://samba.anu.edu.au/ftp/rsync/src/rsync-3.0.8.tar.gz"
hset rsync depends "busybox"

deploy-rsync() {
	deploy cp "$STAGING_USR"/bin/rsync "$ROOTFS"/bin/
}

# 110906 Checked http://code.google.com/p/picocom/
PACKAGES+=" picocom"
hset picocom url "http://picocom.googlecode.com/files/picocom-1.6.tar.gz"
hset picocom depends "busybox"

compile-picocom() {
	compile make CC="$GCC" CFLAGS="$CFLAGS"
}
install-picocom() {
	log_install cp picocom "$STAGING_USR"/bin/
}
deploy-picocom() {
	deploy cp "$STAGING_USR"/bin/picocom "$ROOTFS"/bin/
}

# From xfs repo. BSD borken configure/install
# 110906 Broken Repo ? timeout
PACKAGES+=" libattr"
hset libattr url "ftp://oss.sgi.com/projects/xfs/cmd_tars/attr_2.4.43-1.tar.gz"
hset libattr depends "busybox"
hset libattr prefix "/"

configure-libattr-local() {
#	autoreconf --install --force
	sed -i \
		-e 's|) --mode=compile|) --tag=CC --mode=compile|' \
		-e 's|) --mode=link|) --tag=CC --mode=link|' \
			include/buildmacros
	configure-generic-local
}
configure-libattr() {
	configure configure-libattr-local
}

install-libattr() {
	export DIST_ROOT="$STAGING_USR"
	install-generic
	unset DIST_ROOT
}

# Libcap for /sbin/setcap
# 110906 Updated 2.22 http://www.kernel.org/pub/linux/libs/security/linux-privs/kernel-2.6/
PACKAGES+=" libcap"
hset libcap url "http://www.kernel.org/pub/linux/libs/security/linux-privs/kernel-2.6/libcap-2.22.tar.gz"
hset libcap depends "libattr"
hset libcap destdir "$STAGING_USR"

configure-libcap() {
	# silly rules uses host ld to find where libraries are
	configure sed -i -e 's|^lib=.*|lib=lib|g' Make.Rules
}
compile-libcap() {
	compile make CC="$GCC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS_RLINK" \
		DESTDIR="$STAGING_USR"
}
install-libcap() {
	install-generic RAISE_SETFCAP=no 
}
deploy-libcap() {
	deploy deploy_binaries
}

# http://www.net-snmp.org/download.html
PACKAGES+=" libnetsnmp"
hset libnetsnmp url "http://downloads.sourceforge.net/project/net-snmp/net-snmp/5.5/net-snmp-5.5.tar.gz#netsnmp-5.5.tgz"
hset libnetsnmp depends "openssl"
hset libnetsnmp configscript "net-snmp-config"

configure-libnetsnmp() {
	configure-generic \
		--with-defaults \
		--with-openssl="$STAGING_USR" \
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

