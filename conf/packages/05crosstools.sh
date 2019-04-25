
echo GCC PATH = $GCC
echo COMMAND_PACKAGE $COMMAND_PACKAGE
if [ ! -f "$GCC" -o "$COMMAND_PACKAGE" == "crosstools" ]; then
	PACKAGES+=" crosstools"
	TARGET_PACKAGES+=" crosstools"
fi

CROSSTOOL_JOBS=".$MINIFS_JOBS"

hset crosstools url "git!https://github.com/crosstool-ng/crosstool-ng.git#crosstool-ng-$MINIFS_BOARD.tar.bz2"
#hset crosstools git-ref 'fd9fe523b22cb6281f26081232a3f8f3aee7fda1'
hset crosstools git-ref 'b2151f1dba2b20c310adfe7198e461ec4469172b'

hset crosstools depends "host-libtool host-automake"

# ${HOME}/x-tools/${CT_TARGET}
# MINIFS_TOOLCHAIN/${CT_TARGET}

hostcheck-crosstools() {
	for cmd in gawk bison flex gperf libtool autoconf automake; do
		local p=$(which $cmd)
		if [ ! -x "$p" ]; then
			echo "### ERROR: Package $PACKAGE needs command $cmd"
			HOSTCHECK_FAILED=1
		fi
	done
}

patch-crosstools() {
	if [ -d "$PATCHES/crosstools/patches" ]; then
		echo "** crosstools ** Adding extra patches"
		rsync -av "$PATCHES/crosstools/patches/" ./patches/
	fi
}

reset-crossrools-env() {
	export PATH="$BASE_PATH"
	unset CC CXX GCC LD CFLAGS CXXFLAGS CPPFLAGS LDFLAGS ACLOCAL LIBTOOL;
	unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR LD_LIBRARY_PATH ;
}

configure-crosstools() {
	(	# make sure the environment is clean before we start here
		reset-crossrools-env
		# remove "read only" mode
		chmod -R u+w "$TOOLCHAIN"

		# Install missing patches
		for dir in "$PATCHES"/crosstools; do
			if [ -d "$dir"/patches ]; then
				here=$(pwd)
				pushd "$dir"
				tar cf - patches | (cd "$here"; tar xvf -)
				popd
			fi
		done
		if [ ! -f configure ]; then
			./bootstrap
		fi
		configure ./configure --prefix="$STAGING_TOOLS" &&
			$MAKE &&
			$MAKE install || exit 1
	)

	mkdir -p "$TOOLCHAIN_BUILD"

	# handles crosstools_menuconfig and so on
	if [ "$COMMAND_PACKAGE" = "crosstools" ] ; then
		set -x
		pushd "$TOOLCHAIN_BUILD"
			reset-crossrools-env
			rm -f config_crosstools.conf config_uclibc.conf .config
			for cf in "$CONFIG"/config_crosstools.conf "$CONFIG"/config_uclibc.conf ; do
				if [ -f "$cf" ]; then
					cp "$cf" .
				fi
			done
			cp config_crosstools.conf .config
			"$STAGING_TOOLS"/bin/ct-ng $COMMAND_TARGET &&
			"$STAGING_TOOLS"/bin/ct-ng show-tuple &&
			cp .config config_crosstools.conf
			for cf in config_crosstools.conf config_uclibc.conf ; do
				if [ -f "$cf" ]; then
					cp "$cf" "$CONFIG"/
				fi
			done
			rm -f config_crosstools.conf config_uclibc.conf .config
			exit
		popd
	fi

	(
		reset-crossrools-env
		pushd "$TOOLCHAIN_BUILD"
		rm -f config* .config log.*
		# doctor new config
		for cf in "$CONFIG"/config_crosstools.conf "$CONFIG"/config_uclibc.conf ; do
			dst=$(basename $cf)
			if [ -f $cf ]; then
				cat $cf | sed \
					-e "s|MINIFS_TOOLCHAIN_BUILD|$TOOLCHAIN_BUILD|g" \
					-e "s|MINIFS_TOOLCHAIN|$TOOLCHAIN|g" \
					-e "s|MINIFS_ROOT|$BASE|g" \
					-e "s|MINIFS_STAGING|$STAGING|g" \
					-e "s|MINIFS_KERNEL|$BUILD/linux|g" \
					-e "s|MINIFS_CFLAGS|$TARGET_LIBC_CFLAGS|g" \
					 >"$TOOLCHAIN_BUILD"/$dst
			fi
		done

		cp config_crosstools.conf .config
		"$STAGING_TOOLS"/bin/ct-ng show-tuple
		"$STAGING_TOOLS"/bin/ct-ng build$CROSSTOOL_JOBS || exit 1
	); ret=$?

	return $ret
}

compile-crosstools() {
	compile echo Done
}

# installing crosstools is just the beginning!
install-crosstools() {
	GCC=$(which $TARGET_FULL_ARCH-gcc)
	if [ ! -f "$GCC" ]; then
		echo "ERROR: TARGET_FULL_ARCH-gcc doesn't exists!! $GCC"
		echo PATH= $PATH
		exit 1
	fi
	log_install echo Done
}


PACKAGES+=" host-libtool"
hset host-libtool url "http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz"
hset host-libtool destdir "/"
hset host-libtool depends "host-installwatch"

setup-host-libtool() {
	export LIBTOOL="$TARGET_FULL_ARCH"-libtool
}
configure-host-libtool() {
	(
		host-setup
		configure ./configure \
			--prefix=$STAGING_TOOLS \
			--build=$(gcc -dumpmachine) \
			--host=$TARGET_SMALL_ARCH \
			--program-prefix="$TARGET_FULL_ARCH"- #CC=$TARGET_FULL_ARCH-gcc
	) || exit 1
}
install-host-libtool() {
	install-generic || return 1
	ln -f -s "$TARGET_FULL_ARCH"-libtool "$STAGING_TOOLS"/bin/libtool
	ln -f -s "$TARGET_FULL_ARCH"-libtoolize "$STAGING_TOOLS"/bin/libtoolize
}

PACKAGES+=" host-automake"
#hset host-automake url "http://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.xz"
hset host-automake url "http://ftp.gnu.org/gnu/automake/automake-1.15.1.tar.xz"
hset host-automake destdir "/"
hset host-automake depends "host-autoconf"

configure-host-automake() {
	(
		host-setup
		configure ./configure \
			--prefix=$STAGING_TOOLS \
			--build=$(gcc -dumpmachine) \
			--host=$TARGET_SMALL_ARCH
	) || exit 1
}

PACKAGES+=" host-autoconf"
hset host-autoconf url "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz"
hset host-autoconf destdir "/"
hset host-autoconf depends "host-installwatch"

configure-host-autoconf() {
	(
		host-setup
		configure ./configure \
			--prefix=$STAGING_TOOLS \
			--build=$(gcc -dumpmachine) \
			--host=$TARGET_SMALL_ARCH
	) || exit 1
}

PACKAGES+=" host-pkg-config"
hset host-pkg-config url "http://ftp.de.debian.org/debian/pool/main/p/pkg-config/pkg-config_0.26.orig.tar.gz"
hset host-pkg-config depends "host-autoconf"
hset host-pkg-config destdir "/"

configure-host-pkg-config() {
	(
		host-setup
		configure ./configure \
			--prefix=$STAGING_TOOLS \
			--build=$(gcc -dumpmachine) \
			--host=$TARGET_FULL_ARCH \
			--program-prefix="$TARGET_FULL_ARCH"-
	) || exit 1
}

PACKAGES+=" host-installwatch"
hset host-installwatch url "git!https://github.com/buserror-uk/checkinstall.git#checkinstall-git.tar.bz2"
hset host-installwatch destdir "$STAGING_TOOLS"
hset host-installwatch dir "host-installwatch/installwatch"

configure-host-installwatch() {
	configure-generic echo Done
}
install-host-installwatch() {
	log_install make install PREFIX=$STAGING_TOOLS
}

PACKAGES+=" gdbserver"
hset gdbserver url "none"
hset gdbserver dir "."
hset gdbserver phases "deploy"
hset gdbserver depends "busybox"

deploy-gdbserver() {
	local src="$CROSS_BASE/$TARGET_FULL_ARCH"/debug-root/usr/bin/gdbserver
	if [ -f "$src" ]; then
		mkdir -p "$ROOTFS"/usr/bin
		cp "$src" "$ROOTFS"/usr/bin/
	else
		echo WARNING gdbserver not found in toolchains install
	fi
}

PACKAGES+=" catchsegv"
hset catchsegv url "none"
hset catchsegv dir "."
hset catchsegv phases "deploy"
hset catchsegv depends "busybox"

deploy-catchsegv() {
	local src="$CROSS_BASE/$TARGET_FULL_ARCH"/sysroot/usr/bin/catchsegv
	if [ -f "$src" ]; then
		ROOTFS_KEEPERS+="libSegFault.so:"
		mkdir -p "$ROOTFS"/usr/bin
		cp "$src" "$ROOTFS"/usr/bin/
	fi
}

PACKAGES+=" strace"
hset strace url "http://downloads.sourceforge.net/project/strace/strace/4.9/strace-4.9.tar.xz"
hset strace depends "busybox"

configure-strace() {
	sed -i -e 's|#undef HAVE_LINUX_NETLINK_H|#define HAVE_LINUX_NETLINK_H 1|' \
		config.h.in
	configure-generic # --enable-static --disable-shared LDFLAGS=-static
}

deploy-strace() {
	mkdir -p "$ROOTFS"/usr/bin
	deploy cp "$STAGING_USR"/bin/strace "$ROOTFS"/usr/bin/
}

PACKAGES+=" gdb"
hset gdb url "http://ftp.gnu.org/gnu/gdb/gdb-7.3.1.tar.bz2"
hset gdb depends "libtool libncurses"

deploy-gdb() {
	deploy deploy_binaries
}

PACKAGES+=" host-gdb"
hset host-gdb url "http://ftp.gnu.org/gnu/gdb/gdb-8.0.1.tar.xz"
hset host-gdb destdir "/"

configure-host-gdb() {
	(
		host-setup
		configure ./configure \
			--prefix=$STAGING_TOOLS \
			--build=$(gcc -dumpmachine) \
			--host=$TARGET_FULL_ARCH
	) || exit 1
}

PACKAGES+=" gdbserver-gdb"
hset gdbserver-gdb url "http://ftp.gnu.org/gnu/gdb/gdb-8.0.1.tar.xz"
hset gdbserver-gdb dir "gdbserver-gdb/gdb/gdbserver"
hset gdbserver-gdb depends "busybox"

deploy-gdbserver-gdb() {
	deploy deploy_binaries
}
