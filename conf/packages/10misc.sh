
# 160606 Updated 2.1.7 http://samba.org/ftp/talloc/
PACKAGES+=" libtalloc"
hset libtalloc url "http://samba.org/ftp/talloc/talloc-2.1.7.tar.gz"

patch-libtalloc() {
	cp "$PATCHES/$PACKAGE-make/"* .
}

# Updated 2.0.22
PACKAGES+=" libevent"
hset libevent url "https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz"

configure-libevent() {
	configure-generic \
		--disable-debug-mode \
		--disable-thread-support \
		--disable-malloc-replacement \
		--enable-function-sections
}

compile-libevent() {
	compile-generic \
		CFLAGS="-Os"
}

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

PACKAGES+=" libtasn1"
hset libtasn1 url "http://ftp.gnu.org/gnu/libtasn1/libtasn1-3.3.tar.gz"

PACKAGES+=" libp11-kit"
hset libp11-kit url "http://p11-glue.freedesktop.org/releases/p11-kit-0.17.4.tar.gz"
hset libp11-kit depends "libtasn1"

configure-libp11-kit() {
	configure-generic # --without-libtasn1
}

# 110906 Updated 2.12.10 http://ftp.gnu.org/gnu/gnutls/
#        Now requires libnettle, no libgcrypt
PACKAGES+=" gnutls"
hset gnutls url "http://ftp.gnu.org/pub/gnu/gnutls/gnutls-2.12.21.tar.bz2"
hset gnutls depends "libgcrypt libp11-kit"

configure-gnutls() {
	export LDFLAGS="$LDFLAGS_RLINK"
	for fn in ./gl/m4/stdio_h.m4 ./lib/gl/m4/stdlib_h.m4; do
		sed -i -e 's/GNULIB_GETS=1/GNULIB_GETS=0/g' $fn
	done
	configure-generic \
		--with-libgcrypt \
		--with-libgcrypt-prefix="$STAGING_USR" \
		--with-libreadline-prefix="$STAGING_USR" \
		--disable-rpath
	export LDFLAGS="$LDFLAGS_BASE"
}

#######################################################################
## OpenSSL - http://www.openssl.org/
#######################################################################
# 110906 Updated 1.0.0e
PACKAGES+=" openssl"
hset openssl url "http://www.openssl.org/source/openssl-1.0.2q.tar.gz"
hset openssl targets "openssl openssl-bin"
hset openssl deploy false
hset openssl config "linux-generic32"

configure-openssl() {
	local conf=$(hget openssl config)
	configure ./Configure --prefix=/usr --install_prefix="$STAGING" shared $conf
}
compile-openssl() {
	local base=$(awk '/^CFLAG= / {print substr($0,8);}' Makefile)
	compile $MAKE $MAKE_ARGUMENTS \
		CC="ccfix $TARGET_FULL_ARCH-gcc" \
		AR="ccfix $TARGET_FULL_ARCH-ar r" \
		RANLIB="$TARGET_FULL_ARCH-ranlib" \
		CFLAG="$base $TARGET_CFLAGS"
}
install-openssl() {
	# skip all the docs, it breaks anyway
	log_install $MAKE install_sw
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
PACKAGES+=" libcurl"
hset libcurl url "http://curl.haxx.se/download/curl-7.48.0.tar.bz2"

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

# Checked http://samba.anu.edu.au/rsync/
PACKAGES+=" rsync"
hset rsync url "http://samba.anu.edu.au/ftp/rsync/src/rsync-3.1.2.tar.gz"
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
#hset libnetsnmp url "http://downloads.sourceforge.net/project/net-snmp/net-snmp/5.5.1/net-snmp-5.5.1.tar.gz#netsnmp-5.5.1.tgz"
hset libnetsnmp url "http://sourceforge.net/projects/net-snmp/files/net-snmp/5.7.2/net-snmp-5.7.2.tar.gz#netsnmp-5.7.2.tgz"
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

PACKAGES+=" evtest"
hset evtest url "http://cgit.freedesktop.org/evtest/snapshot/evtest-1.31.tar.gz"

configure-evtest() {
	export LDFLAGS="$LDFLAGS_RLINK -lm"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"
}
deploy-evtest(){
	deploy deploy_binaries
}

PACKAGES+=" e2fsprogs"
hset e2fsprogs url "http://switch.dl.sourceforge.net/project/e2fsprogs/e2fsprogs/1.42/e2fsprogs-1.42.tar.gz"

configure-e2fsprogs(){
	export LDFLAGS="$LDFLAGS_RLINK -lm"
	configure-generic --disable-defrag --disable-tls
	export LDFLAGS="$LDFLAGS_BASE"
}

PACKAGES+=" libargp"
hset libargp url "http://www.auto.tuwien.ac.at/~mkoegler/eib/argp-standalone-1.3.tar.gz"

# Requires 'argp.h' that is not in uclibc
PACKAGES+=" elfutils"
hset elfutils url "https://fedorahosted.org/releases/e/l/elfutils/0.155/elfutils-0.155.tar.bz2"
hset elfutils depends "libargp"
hset elfutils optional "lzma"

configure-elfutils-local() {
	cat <<-END >libintl.h
	#ifndef _LIBINTL_H
	#define _LIBINTL_H      1
	#define gettext(a)              (a)
	#define dgettext(a,b)           (b)
	#define setlocale(a, b)         ;
	#define bindtextdomain(a, b)    ;
	#define textdomain(a)           ;
	#endif
	END
	rm -f configure
	sed -i -e '/no_Werror/d' config/eu.am
	configure-generic-local --disable-nls --disable-tls
}

configure-elfutils() {
	configure configure-elfutils-local
}

PACKAGES+=" procps"
hset procps url "http://ftp.de.debian.org/debian/pool/main/p/procps/procps_3.3.3.orig.tar.xz"
hset procps deploy "vmstat"
#hset procps compile "vmstat"
#ij        m4_esyscmd([misc/git-version-gen .tarball-version]),

configure-procps() {
	# prevents errors with rpl_malloc
	export ac_cv_func_malloc_0_nonnull=yes
	export ac_cv_func_realloc_0_nonnull=yes

	sed -i -e '/AC_FUNC_MALLOC|AC_FUNC_REALLOC/d' \
		-e "s|misc/git-version-gen .tarball-version|echo stable\|tr -d '\\n'|" \
		configure.ac
	sed -i -e '/update-potfiles/d' autogen.sh
	rm -f configure
	configure-generic --disable-nls --without-ncurses
	unset ac_cv_func_malloc_0_nonnull
	unset ac_cv_func_realloc_0_nonnull
}

deploy-procps-local() {
	local lst=$(hget procps deploy)
	if [ "$lst" != "" ]; then
		mkdir -p "$ROOTFS"/usr/bin/
		for l in $lst; do
			for src in $STAGING_USR/usr/bin/$l \
				$STAGING_USR/usr/usr/bin/$l \
				$STAGING_USR/usr/sbin/$l; do
				if [ -x $src ]; then
					echo deploying $src
					cp $src "$ROOTFS"/usr/bin/
				fi
			done
		done
	else
		deploy_binaries
	fi
}

deploy-procps() {
	deploy deploy-procps-local
}

PACKAGES+=" cpuburn"
hset cpuburn url "http://ftp.de.debian.org/debian/pool/main/c/cpuburn/cpuburn_1.4a.orig.tar.gz"

compile-cpuburn() {
	compile make -C ARM CC=$GCC
}

install-cpuburn() {
	log_install cp ARM/burnCortexA8 "$STAGING_USR"/bin/
}

deploy-cpuburn() {
	deploy cp "$STAGING_USR"/bin/burn* "$ROOTFS"/bin/
}

PACKAGES+=" libconfig"
hset libconfig url "http://www.hyperrealm.com/libconfig/libconfig-1.5.tar.gz"


PACKAGES+=" librpmatch"
hset librpmatch url "https://github.com/pullmoll/musl-rpmatch/archive/v1.0.tar.gz"

# bypass the pile of autoshit that doesn't work to build a library with just that c/h file we need

compile_librpmatch-local() {
cat << EOF >config.h
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_REGEX_H 1
#define HAVE_LIBINTL_H 1
#define HAVE_LOCALE_H 1
EOF

	"$TARGET_FULL_ARCH"-gcc $TARGET_CFLAGS -c *.c && \
		"$TARGET_FULL_ARCH"-ar cr "$PACKAGE.a"
}

compile-librpmatch() {
	compile compile_librpmatch-local
}

install-librpmatch() {
	log_install cp "$PACKAGE.a" "$STAGING_USR"/lib/
}

PACKAGES+=" pciutils"
hset pciutils url "https://github.com/pciutils/pciutils/archive/v3.6.2.tar.gz"

