
PACKAGES+=" lua"
hset lua url "http://www.lua.org/ftp/lua-5.1.4.tar.gz"
hset lua depends "libreadline libncurses busybox"
hset lua destdir "none"

configure-lua() {
	configure echo Done
}
compile-lua() {
	compile-generic linux CC=$GCC MYLDFLAGS="$LDFLAGS"
}
install-lua() {
	install-generic INSTALL_TOP="$STAGING_USR"
}

PACKAGES+=" toluapp"
hset toluapp url "http://www.codenix.com/~tolua/tolua++-1.0.93.tar.bz2"
hset toluapp depends "lua"

configure-toluapp() {
	configure echo Done
}
compile-toluapp() {
	compile-generic DESTDIR="$STAGING_USR"
}
install-toluapp() {
	install-generic 
}


PACKAGES+=" slang"
hset slang url "http://ftp.de.debian.org/debian/pool/main/s/slang2/slang2_2.2.4.orig.tar.bz2"

compile-slang() {
	compile $MAKE # no jobs
}

PACKAGES+=" tcc"
hset tcc url "git!git://repo.or.cz/tinycc.git#tinycc-git.tar.bz2"

configure-tcc() {
	local extra=""
	local local_cflags;
	case $TARGET_ARCH in
		arm) 
			extra+=" --cpu=armv4l"
			local_cflags="-DTCC_UCLIBC -DTCC_ARM_EABI"
			;;
	esac
	configure-generic \
		--cross-prefix="$CROSS-" \
		--extra-cflags="$CPPFLAGS $TARGET_CFLAGS $local_cflags" \
		--extra-ldflags="$TARGET_LDFLAGS" \
		--with-libgcc \
		$extra
}

install-tcc-local() {
	install-generic-local
	rm -rf "$STAGING_USR"/lib/tcc/win32
}

install-tcc() {
	log_install install-tcc-local
}

deploy-tcc() {
	deploy	deploy_binaries
}
