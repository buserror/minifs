
if [ ! -f "$GCC" ]; then 
	PACKAGES="$PACKAGES crosstools"
	NEED_CROSSTOOLS="crosstools"
	TARGET_PACKAGES+=" crosstools"
fi
hset url crosstools	"http://ymorin.is-a-geek.org/download/crosstool-ng/crosstool-ng-${VERSION_crosstools}.tar.bz2" 

configure-crosstools() {
	# this patch is needed on newer host kernels
	for pd in "$PATCHES/uclibc" "$PATCHES/uclibc-${TARGET_BOARD}"; do
		if [ -d $pd ]; then
			echo "##### Installing $pd patches"
			cp $pd/*.patch patches/uClibc/0.9.30.1/
		fi
	done

	configure ./configure --prefix="$TOOLCHAIN" &&
		$MAKE &&
		$MAKE install

	mkdir -p "$TOOLCHAIN_BUILD"

	# handles crosstools_menuconfig and so on
	if [ "$COMMAND_PACKAGE" = "crosstools" ] ; then
		pushd "$TOOLCHAIN_BUILD"
			rm -f config_crosstools.conf config_uclibc.conf .config
			cp "$CONFIG"/config_crosstools.conf \
				"$CONFIG"/config_uclibc.conf .
			cp config_crosstools.conf .config
			"$TOOLCHAIN"/bin/ct-ng $COMMAND_TARGET &&
			cp .config config_crosstools.conf &&
			cp config_crosstools.conf config_uclibc.conf \
				"$CONFIG"/ &&
			rm -f config_crosstools.conf config_uclibc.conf .config
			exit
		popd	
	fi

	pushd "$TOOLCHAIN_BUILD"
		rm -f config* .config log.*
		# doctor new config
		for cf in "$CONFIG"/config_crosstools.conf "$CONFIG"/config_uclibc.conf ; do
			dst=$(basename $cf)
			cat $cf | sed \
				-e "s|MINIFS_TOOLCHAIN_BUILD|$TOOLCHAIN_BUILD|g" \
				-e "s|MINIFS_TOOLCHAIN|$TOOLCHAIN|g" \
				-e "s|MINIFS_ROOT|$BASE|g" \
				-e "s|MINIFS_STAGING|$STAGING|g" \
				-e "s|MINIFS_KERNEL|$KERNEL|g" \
				-e "s|MINIFS_CFLAGS|$LIBC_CFLAGS|g" \
				 >"$TOOLCHAIN_BUILD"/$dst
		done

		cp config_crosstools.conf .config
		( unset CC CXX GCC LD CFLAGS CXXFLAGS CPPFLAGS LDFLAGS ACLOCAL; 
		  unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR
		"$TOOLCHAIN"/bin/ct-ng build )
		#"$STAGING"/bin/ct-ng build.4
	popd
}

compile-crosstools() {
	compile echo Done
}

# installing crosstools is just the beginning!
install-crosstools() {
	if [ ! -f "$GCC" ]; then 
		echo "GCC doesn't exists!! $GCC"
		exit 1
	fi
	log_install echo Done
}

PACKAGES+=" systemlibs"
hset url systemlibs "none"
hset dir systemlibs "."

configure-systemlibs() {
	configure echo Done
}
compile-systemlibs() {
	compile echo Done
}
install-systemlibs() {
	log_install rsync -a \
		"$TOOLCHAIN/$TARGET_FULL_ARCH"/sys-root/lib \
		"$STAGING"/
}


PACKAGES+=" gdbserver"
hset url gdbserver "none"
hset dir gdbserver "."
hset phases gdbserver "deploy"

deploy-gdbserver() {
	local src="$TOOLCHAIN/$TARGET_FULL_ARCH"/debug-root/usr/bin/gdbserver
	if [ -f "$src" ]; then
		mkdir -p "$ROOTFS"/usr/bin
		cp "$src" "$ROOTFS"/usr/bin/gdbserver
	fi
}


