
if [ ! -f "$GCC" -o "$COMMAND_PACKAGE" == "crosstools" ]; then 
	PACKAGES+=" crosstools"
	NEED_CROSSTOOLS="crosstools"
	TARGET_PACKAGES+=" crosstools"
fi
hset url crosstools	"http://ymorin.is-a-geek.org/download/crosstool-ng/crosstool-ng-${VERSION_crosstools}.tar.bz2" 
hset depends crosstools "linux-headers"

configure-crosstools() {
	# remove "read only" mode
	chmod -R u+w "$TOOLCHAIN"

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
hset depends systemlibs "crosstools"

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
hset depends gdbserver "busybox"

deploy-gdbserver() {
	local src="$TOOLCHAIN/$TARGET_FULL_ARCH"/debug-root/usr/bin/gdbserver
	if [ -f "$src" ]; then
		mkdir -p "$ROOTFS"/usr/bin
		cp "$src" "$ROOTFS"/usr/bin/gdbserver
	fi
}

PACKAGES+=" strace"
hset url strace "http://kent.dl.sourceforge.net/project/strace/strace/4.5.19/strace-4.5.19.tar.bz2"
hset depends strace "busybox"

configure-strace() {
	sed -i -e 's|#undef HAVE_LINUX_NETLINK_H|#define HAVE_LINUX_NETLINK_H 1|' \
		config.h.in
	configure-generic
}

deploy-strace() {
	deploy cp "$STAGING_USR"/bin/strace "$ROOTFS"/usr/bin/
}
