
PACKAGES+=" lua"
hset url lua "http://www.lua.org/ftp/lua-5.1.4.tar.gz"
hset depends lua "libreadline libncurses busybox"
hset destdir lua "none"

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
hset url toluapp "http://www.codenix.com/~tolua/tolua++-1.0.93.tar.bz2"
hset depends toluapp "lua"

configure-toluapp() {
	configure echo Done
}
compile-toluapp() {
	compile-generic DESTDIR="$STAGING_USR"
}
install-toluapp() {
	install-generic 
}
