
# IMPORTANT NOTE:
# THis requires the glibc-dev:i386 to build, as the gcc -m32 needed to build
# will fail to find headers if these system host headers are not installed 
# on a x86_64 system. You also need a -multilib version of gcc
PACKAGES+=" luajit"
hset luajit url "http://luajit.org/download/LuaJIT-2.0.2.tar.gz"
hset luajit desc "A Just-In-Time compiler for lua"

configure-luajit() {
	configure echo Done
}
compile-luajit() {
	(
	unset CFLAGS
	compile-generic PREFIX=/usr CROSS="$TARGET_FULL_ARCH"- MYLDFLAGS="$LDFLAGS" \
		BUILDMODE=dynamic Q= \
		TARGET_CFLAGS="$TARGET_CPPFLAGS $TARGET_CFLAGS" \
		HOST_CC="gcc -m32"
	) || return 1;
}
install-luajit() {
	install-generic PREFIX=/usr
}
deploy-luajit-local() {
	deploy_binaries
	deploy_staging_path "/usr/share/luajit-2.0.0" "/"
}
deploy-luajit() {
	deploy deploy-luajit-local
}

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
