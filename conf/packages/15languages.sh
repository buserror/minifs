
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

