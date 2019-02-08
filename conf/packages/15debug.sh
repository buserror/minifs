
PACKAGES+=" valgrind"
#hset valgrind url "http://valgrind.org/downloads/valgrind-3.8.1.tar.bz2"
hset valgrind url "http://valgrind.org/downloads/valgrind-3.11.0.tar.bz2"

configure-valgrind-local() {
	(
		export CC="$TARGET_FULL_ARCH-gcc"
		export AR="$TARGET_FULL_ARCH-ar"
	#	CFLAGS+=" -I$BUILD/linux/include"
		CFLAGS+=" -D__STRUCT_EXEC_OVERRIDE__"
		sed -i -e 's/armv7/arm/g' configure.in
		rm -f configure
		# cheat!!
		# we need to fake the fact we are in 32 bits
		# TARGET_FULL_ARCH=${TARGET_FULL_ARCH/64/}
		# Another hack, tell it we are armv7  not just plain arm
		TARGET_FULL_ARCH=${TARGET_FULL_ARCH/arm-/armv7-}
		configure-generic-local
	) || return 1
}
configure-valgrind() {
	configure configure-valgrind-local
}

deploy-valgrind() {
	deploy deploy_binaries
}
