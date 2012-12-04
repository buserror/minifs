
PACKAGES+=" node"
hset node url "http://nodejs.org/dist/v0.8.15/node-v0.8.15.tar.gz"
hset node depends "openssl zlib"

configure-node-local() {
	(
	export LD="$CC"
	./configure  --dest-cpu=$TARGET_ARCH --dest-os=linux \
		 --without-snapshot --prefix=/usr \
		 --shared-zlib \
		 --with-arm-float-abi=softfp
	) || return 1
}
configure-node() {
	configure configure-node-local
}

compile-node-local() {
	(
	export CFLAGS="$CFLAGS $TARGET_CPPFLAGS"
	export CXXFLAGS="$CXXFLAGS $TARGET_CPPFLAGS"
	export LDFLAGS="$LDFLAGS_RLINK -lstdc++"
	compile-generic
	) || return 1
}
compile-node() {
	compile compile-node-local
}

install-node-local() {
	(
	export CFLAGS="$CFLAGS $TARGET_CPPFLAGS"
	export CXXFLAGS="$CXXFLAGS $TARGET_CPPFLAGS"
	export LDFLAGS="$LDFLAGS_RLINK -lstdc++"
	install-generic -j$MINIFS_JOBS
	) || return 1
}
install-node() {
	log_install install-node-local
}
deploy-node() {
	deploy deploy_binaries
}
