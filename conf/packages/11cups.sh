
PACKAGES+=" openslp"
hset openslp url "http://downloads.sourceforge.net/project/openslp/OpenSLP/1.2.1/openslp-1.2.1.tar.gz"

PACKAGES+=" cups"
hset cups url "http://ftp.easysw.com/pub/cups/1.5.0/cups-1.5.0-source.tar.bz2"
hset cups depends "busybox openssl libpng libjpeg libtiff mDNSResponder"
hset cups configscript "cups-config"

configure-cups-local() {
	export DSOFLAGS="$LDFLAGS_RLINK"
	export LDFLAGS=$LDFLAGS_RLINK
	export DSO=":"
	rm -f configure
	# replace lame shell with ours
	echo 'exec install $*' >install-sh
	configure-generic BUILDROOT=$STAGING \
		INSTALL=install \
		LIBCUPS=libdups.so.1 \
		--without-php \
		--without-perl \
		--without-python \
		--without-java \
		--disable-gssapi \
		--disable-largefile \
		--disable-relro \
		--disable-unit_tests \
		--disable-libusb \
		--enable-dnssd \
		--disable-slp \
		--with-pdftops=gs \
		--disable-libtool-unsupported
	export LDFLAGS=$LDFLAGS_BASE
	unset DSOFLAGS
}
configure-cups() {
	configure configure-cups-local 
}
compile-cups() {
	compile-generic BUILDROOT=$STAGING \
		CC="ccfix $TARGET_FULL_ARCH-gcc" 
}
install-cups-local() {
	rm -rf "$STAGING_USR"/share/cups "$STAGING_USR"/etc/cups
	install-generic-local BUILDROOT=$STAGING \
		CC="ccfix $TARGET_FULL_ARCH-gcc" 
}
install-cups() {
	log_install install-cups-local
}
deploy-cups-local() {
	set -x
	deploy_staging_path /usr/share/cups "/" 
	deploy_staging_path /usr/share/doc/cups "/"
	deploy_binaries
	mkdir -p \
		$ROOTFS/var/cache/cups/rss \
		$ROOTFS/var/spool/cups/tmp \
		$ROOTFS/var/run/cups/certs
	set +x
}
deploy-cups() {
	ROOTFS_KEEPERS+="libcupscgi.so.1:libcupsdriver.so.1:"
	ROOTFS_PLUGINS+="$ROOTFS/lib/cups:"
	deploy deploy-cups-local
}

PACKAGES+=" libjbig2dec"
hset libjbig2dec url "http://ghostscript.com/~giles/jbig2/jbig2dec/jbig2dec-0.11.tar.gz"
hset libjbig2dec depends "libpng"

configure-libjbig2dec-local() {
	autoreconf --force; libtoolize --force; automake --force --add-missing
	configure-generic-local
}
configure-libjbig2dec() {
	configure configure-libjbig2dec-local
}

PACKAGES+=" lcms"
hset lcms url "http://downloads.sourceforge.net/project/lcms/lcms/2.2/lcms2-2.2.tar.gz"

PACKAGES+=" libopenjpeg"
hset libopenjpeg url "http://openjpeg.googlecode.com/files/openjpeg_v1_4_sources_r697.tgz"
hset libopenjpeg depends "lcms"

configure-libopenjpeg-local() {
	sed -i -e "s|-std=c99$|-std=c99 $CFLAGS|" libopenjpeg/Makefile.am
	autoreconf --force; libtoolize --force; automake --force --add-missing
	configure-generic-local --enable-shared
}
configure-libopenjpeg() {
	configure configure-libopenjpeg-local
}
compile-libopenjpeg() {
	# can't use concurent make with this
	compile $MAKE  INSTALL=/usr/bin/install
}

PACKAGES+=" ghostscript"
#hset ghostscript url "http://downloads.ghostscript.com/public/ghostscript-9.04.tar.gz"
# no longer need lcms with the git version
hset ghostscript url "git!git://git.ghostscript.com/ghostpdl.git#ghostscript-git.tar.bz2"
hset ghostscript depends "cups libjpeg libpng libtiff libexpat zlib libfontconfig"
hset ghostscript dir "ghostscript/gs"

configure-ghostscript-local() {
	if [ -f ./lcms2/include/icc34.h ];then
		cp ./lcms2/include/icc34.h base/
	fi
	rm -rf expat jasper jpeg libpng tiff zlib freetype lcms2
	rm -rf jbig2dec
#	rm -rf lcms
#      -e 's|WHICH_CMS=lcms$|WHICH_CMS=lcms2|' 
#      -e 's|SHARE_LCMS=0|SHARE_LCMS=1|' 
   	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic-local \
		--with-system-libtiff \
		--without-jbig2dec \
		--without-jasper \
		--with-install-cups \
		--disable-compile-inits CCAUX=gcc || return 1
	sed -i  -e 's|SHARE_LCMS2=0|SHARE_LCMS2=1|' \
        -e "s|LCMS2SRCDIR=.*$|LCMS2SRCDIR=$BUILD/lcms|" \
        -e 's|=imdi|&\n\n# Use system expat library\n\nSHARE_EXPAT=1|' \
        -e 's|SHARE_FT=0|SHARE_FT=1|' \
        -e 's|SHARE_LIBTIFF=$|SHARE_LIBTIFF=1|' \
        -e 's|CCAUX=.*$|CCAUX=gcc|' \
        -e "s|CUPSSERVERBIN=$STAGING|CUPSSERVERBIN=|" \
        -e "s|CUPSDATA=$STAGING|CUPSDATA=|" \
        -e "s|CUPSSERVERROOT=$STAGING_USR|CUPSSERVERROOT=|" \
        Makefile  || return 1
    LDFLAGS="$LDFLAGS_BASE"
	mkdir -p obj/aux
}
configure-ghostscript() {
	configure configure-ghostscript-local
}
compile-ghostscript-local() {
	set -x
	{ 	
		# this compiles a target exec, but runs it with qemu
		# because this idiocy relies on it
		$GCC -o ./obj/aux/genarch ./base/genarch.c -static $CFLAGS
		qemu-$TARGET_ARCH obj/aux/genarch obj/arch.h
		# Now compile the real host tools -- this relies on 
		# the CCAUX that has had to be patched in configure
		$MAKE obj/aux/genconf obj/aux/echogs CC=gcc CFLAGS=-O2
		# and now, the normal build. bleh
		$MAKE $MAKE_ARGUMENTS all cups \
			CFLAGS="-DHAVE_SYS_TIME_H=1 $CPPFLAGS $CFLAGS" \
			LDFLAGS="$LDFLAGS_RLINK"
	} || {
		echo "## build failed"; return 1
	}
	set +x
}
compile-ghostscript() {
	compile compile-ghostscript-local
}
install-ghostscript() {
	# if cups get reinstalled, we need to reinstall too
	if [ ._install_$PACKAGE -ot ../cups/._install_cups ]; then
		rm -f ._install_$PACKAGE
	fi
	install-generic
}
deploy-ghostscript-local() {
	set -x
	ROOTFS_PLUGINS+="$ROOTFS/lib/engines:"
	deploy_staging_path /usr/share/ghostscript "/" \
		--exclude doc --exclude examples
	deploy_binaries
	set +x	
}
deploy-ghostscript() {
	deploy deploy-ghostscript-local
}

# http://www.cl.cam.ac.uk/~mgk25/jbigkit/
PACKAGES+=" libjbig"
hset libjbig url "http://www.cl.cam.ac.uk/~mgk25/download/jbigkit-2.0.tar.gz"

compile-libjbig() {
	compile-generic CC=$TARGET_FULL_ARCH-gcc CCFLAGS="$CFLAGS"
}

# hset splix url  -- for Samsung laser printers
PACKAGES+=" cups-splix"
#hset splix url "http://downloads.sourceforge.net/project/splix/splix/2.0.0/splix-2.0.0.tar.bz2"
hset cups-splix url "splix-svn.tar.bz2"
hset cups-splix depends "cups libjbig"

hostcheck-cups-splix() {
	hostcheck_commands recode ppdc # needed to make the drivers
}
download-cups-splix() {
	pushd "$DOWNLOAD"
	if [ ! -f "splix-svn.tar.bz2" ]; then
			echo "####  Downloading SVN and creating tarball of $PACKAGE"
			svn co "https://splix.svn.sourceforge.net/svnroot/splix/splix" splix-svn &&
			tar jcf splix-svn.tar.bz2 splix-svn &&
			rm -rf splix-svn
	fi
	popd
}
patch-cups-splix() {
	sed -i -e 's|g++|$(CXX)|g' rules.mk
	awk -v arg="$LDFLAGS_RLINK -L../libjbig/libjbig" \
		'/_LDFLAGS/ { $0=$0 " " arg; }{print;}' \
		module.mk >module.mk.new && mv module.mk.new module.mk
	# remove locales
	rm -f ppd/*.ppd
	sed -i -e 's|LANGUAGES[ \t]*:=.*$|LANGUAGES :=|' ppd/Makefile
}
compile-cups-splix() {
	# if cups get reinstalled, we need to reinstall too
	if [ ._compile_$PACKAGE -ot ../cups/._compile_cups ]; then
		rm -f ._compile_$PACKAGE
	fi
	local fl="$CPPFLAGS $CFLAGS -Iinclude -I../libjbig/libjbig -DTHREADS=2 -DCACHESIZE=30"
	compile-generic \
		all ppd \
		V=1 THREADS=2 CACHESIZE=30 \
		CC="ccfix $TARGET_FULL_ARCH-gcc" \
		CXX="ccfix $TARGET_FULL_ARCH-g++" \
		CFLAGS="$fl" \
		CXXFLAGS="$fl" 
}
