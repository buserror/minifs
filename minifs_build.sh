#!/bin/bash

# prerequisites : 
# libtool, bison, flex, genext2fs, squashfs, svn -- probably more
# u-boot-mkimage -- for the arm targets

# NOTE default root password for sshing in is "biff"

# This script generates a minimal root filesystems ready to use
# + It downloads a kernel, crosstools and busybox and does
# + Uncompress the lot, patches if necessary
# + Builds the kernel modules
# + Installs the headers and modules in build/
# + Builds crosstools toolchain
# + Builds and install busybox into rootfs/
# Then
# + Generates a ext3 base filesystem, ready to put on a SD/USB
# 	It is created small, but you can always use resize2fs to "fit"
# 	it to your partition size afterward.
# + Generates a compact squashfs filesystem [optional]
# Then
# + Builds the kernel proper.
# + Builds the "ramdisk" CPIO filesystem using the kernel method
# + Install the kernel+initrd combo file in build
# 
# The resulting kernel + initrd containing a pretty usefull system in 1.4MB
# 
# (C) Michel Pollet <buserror@gmail.com>

# this is the board we are making. Several boards can co-exist, the toolchains
# are "compatible" and live in the toolchain/ subdirectory. Several board of the
# same arch can also coexist, sharing the same toolchain
TARGET_BOARD=${TARGET_BOARD:-"atom"}

COMMAND=$1
COMMAND_PACKAGE=${COMMAND/_*}
COMMAND_TARGET=${COMMAND/*_}

echo TARGET_BOARD $TARGET_BOARD $COMMAND

BASE="$(pwd)"
export MINIFS_BASE="$BASE"

NEEDED_HOST_COMMANDS="make tar rsync installwatch wget git"

export BUILD="$BASE/build-${TARGET_BOARD}"
PATCHES="$BASE/patches"
export STAGING="$BUILD/staging"
export STAGING_USR="$STAGING/usr"
export ROOTFS="$BUILD/rootfs"
export ROOTFS_PLUGINS=""
export ROOTFS_KEEPERS="libnss_dns.so.2:libnss_dns-2.10.2.so:"
export STAGING_TOOLS="$BUILD"/staging-tools
KERNEL="$BUILD/kernel"
CONFIG="$PATCHES/conf-$TARGET_BOARD"
 
source "$PATCHES"/minifs-script-utils.sh
source "$CONFIG"/minifs-script.sh

# remove any package, and it's installed dirs
if [ "$COMMAND_TARGET" == "remove" ]; then
	remove_package $COMMAND_PACKAGE
	exit
fi

TOOLCHAIN="$BASE/toolchain"
TOOLCHAIN_BUILD="$BASE/build-toolchain"
CROSS="$TOOLCHAIN/bin/$TARGET_FULL_ARCH"
GCC="${CROSS}-gcc"

WGET=wget
MAKE=make

mkdir -p "$STAGING_TOOLS"/bin
mkdir -p download "$KERNEL" "$ROOTFS" "$STAGING_USR" "$TOOLCHAIN"/bin
mkdir -p "$STAGING_USR"/share/aclocal

# Always regenerate the rootfs
rm -rf "$ROOTFS"/*

TARGET_INITRD=${TARGET_INITRD:-0}
TARGET_FS_SQUASH=1
TARGET_FS_EXT=1
# only set this if you /know/ the parameters for your NAND
# TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"

# use shared libraries ?
TARGET_SHARED=0

rm -f /tmp/pkg-config.log
for tool in "$PATCHES"/minifs-tools/*.c; do
	tool=$(basename $tool)
	tool=${tool/.c}
	if [ "$STAGING_TOOLS"/bin/$tool -ot "$PATCHES"/minifs-tools/$tool.c ]; then
		echo "#### compiling $tool"
		compile=$(head -1 "$PATCHES"/minifs-tools/$tool.c|sed 's|//||')
		$compile -o "$STAGING_TOOLS"/bin/$tool "$PATCHES"/minifs-tools/$tool.c || exit 1
	fi
done
if [ "$COMMAND" == "tools" ]; then exit ;fi

VERSION_busybox=1.16.1
VERSION_linux=2.6.32.2
VERSION_crosstools=1.6.1

export PATH="$BUILD/staging-tools/bin:$TOOLCHAIN/bin:/usr/sbin:/sbin:$PATH"

export CC="ccfix $TARGET_FULL_ARCH-gcc"
export CXX="ccfix $TARGET_FULL_ARCH-g++"
export LD="ccfix $TARGET_FULL_ARCH-ld"

export TARGET_CPPFLAGS="-I$STAGING/include -I$STAGING_USR/include" 
export CPPFLAGS="$TARGET_CPPFLAGS"
export LDFLAGS_BASE="-L$STAGING/lib -L$STAGING_USR/lib"
export CFLAGS="$TARGET_CFLAGS" 
export CXXFLAGS="$CFLAGS" 
export LIBC_CFLAGS="${LIBC_CFLAGS:-$TARGET_CFLAGS}"
export PKG_CONFIG_PATH="$STAGING/lib/pkgconfig:$STAGING_USR/lib/pkgconfig:$STAGING_USR/share/pkgconfig"
export PKG_CONFIG_LIBDIR="" # do not search local paths
export ACLOCAL="aclocal -I $STAGING_USR/share/aclocal"
export HOST_INSTALL="/usr/bin/install"

# Look in this target's kernel config to know if we need/want modules
CONFIG_MODULES=$(grep '^CONFIG_MODULES=y' "$CONFIG/config_kernel.conf")

# PACKAGES is the entire list of possible packages, as filled by the 
# patches/packages/*.sh scripts, in their ideal build order.
# TARGET_PACKAGES are the ones requested by the target build script, in any
# order
# BUILD_PACKAGES is the same, but with alias resolved so "linux" becomes
# "linux-headers", "linux-modules" etc.
# The script for the union of these and can then have a list of packages
# to build.
# 
export PACKAGES=""
export TARGET_PACKAGES="linux $NEED_CROSSTOOLS systemlibs busybox filesystems"
export BUILD_PACKAGES=""

# in minifs-script, optional
optional board_set_versions

#######################################################################
## Load all the package scripts
#######################################################################
for pd in "$PATCHES/packages" "$CONFIG/packages" ; do
	if [ -d "$pd" ]; then
		# echo "#### Loading $pd"
		for p in "$pd"/*.sh; do 
			source $p
		done
	fi
done

optional board_prepare

# verify we have all the commands we need to build on the host
check_host_commands

if [ "$TARGET_SHARED" -eq 0 ]; then
	echo "### Static build!!"
	LDFLAGS_BASE="-static $LDFLAGS_BASE"
fi
export LDFLAGS_RLINK="$LDFLAGS_BASE -Wl,-rpath-link -Wl,$STAGING/lib -Wl,-rpath-link -Wl,$STAGING_USR/lib"
export LDFLAGS=$LDFLAGS_BASE

if [ "$COMMAND" == "depends" ]; then
	dump-depends
	exit
fi

#######################################################################
## Take all the selected packages, and add their dependencies
## This loops until none of the packages add any more.
#######################################################################
while true; do
	changed=0; newlist=""
	for pack in $TARGET_PACKAGES; do 
		deps=$(hget depends $pack)
		for d in $deps; do
			isthere=0
			for look in $TARGET_PACKAGES; do 
				if [ "$d" = "$look" ]; then
					isthere=1; break
				fi
			done
			if [ $isthere -eq 0 ]; then
			#	echo ADD $pack depends on $d
				newlist+=" $d"; changed=1
			fi
		done
		newlist+=" $pack"
	done
	TARGET_PACKAGES=$newlist
	if [ $changed -eq 0 ]; then break; fi
done

#######################################################################
## Dowmload the files, unpack, and patch them
#######################################################################
pushd download
for package in $TARGET_PACKAGES; do 
	fil=$(hget url $package)

	if [ "$fil" = "" ]; then continue ; fi

	# adds the list of targets provided by this package
	# to the list of the ones we want to build
	targets=$(hget targets $package)
	BUILD_PACKAGES+=" ${targets:-$package}"
	
	if [ "$fil" = "none" ]; then 
		continue
	fi
	
	proto=${fil/!*}
	fil=${fil/*!}
	base=${fil/*\//}
	typ=${fil/*.}
	url=${fil/\#*}
	loc=${base/*#/}
	
	# maybe the package has a magic downloader ?
	optional download-$package

	if [ ! -f "$loc" ]; then
		case "$proto" in
			git)	if [ ! -d "$package.git" ]; then
					echo "#### git clone $url $package.git"
					git clone "$url" "$package.git"
				fi
				if [ -d "$package.git" ]; then
					echo "#### Compressing $url"
					tar jcf "$loc" "$package.git" &&
						rm -rf "$package.git"
				fi
			;;
			svn)	if [ ! -d "$package.svn" ]; then
					echo "#### svn clone $url $package.git"
					svnopt=$(hget svnopt $package)
					case "$svnopt" in 
						none) svnopt=""; ;;
						*) svnopt="-s"; ;;
					esac
					set -x
					git svn clone $svnopt "$url" "$package.svn"
					set +x
				fi
				if [ -d "$package.svn" ]; then
					echo "#### Compressing $url"
					tar jcf "$loc" "$package.svn" &&
						rm -rf "$package.svn"
				fi
			;;
			*) $WGET "$fil" -O "$loc" || exit 1 ;;
		esac
	fi
	baseroot=$package
	#echo $package = $fil
	if [ ! -d "$BUILD/$baseroot" ]; then
		echo "####  Extracting $loc to $BUILD/$baseroot ($typ)"
		mkdir -p "$BUILD/$baseroot"

		case "$typ" in
			bz2)	tar jx --exclude=.git -C "$BUILD/$baseroot" --strip 1 -f "$loc"	;;
			gz|tgz)	tar zx --exclude=.git -C "$BUILD/$baseroot" --strip 1 -f "$loc"	;;
			tarb)	tar zx --exclude=.git -C "$BUILD/$baseroot" -f "$loc" ;;
			run)	pushd "$BUILD/$baseroot"
				optional uncompress-$package "$BASE/download/$loc"
				popd
				;;
			*)	echo ### error file format '$typ' ($base) not supported" ; exit 1
		esac
		for pd in "$CONFIG/$baseroot" "$PATCHES/$baseroot" ; do
			if [ -d "$pd" ]; then
				echo "#### Patching $base"
				pushd "$BUILD/$baseroot"
					for pf in "$pd/"/*.patch; do
						echo "     Applying $pf"
						cat $pf | patch -t -p1
					done
				popd
			fi
		done
	fi
done
popd

# Create the text files used to make the device files in ROOTFS
# the count parameter can't be used because of mksquashfs 
# name    	type mode uid gid major minor start inc count
cat << EOF | tee "$BUILD"/special_file_table.txt |\
	awk '{nod=$2=="c"||$2=="b";print nod?"nod":"dir",$1,"0"$3,$4,$5, nod? $2" "$6" "$7:"";}' \
	>"$BUILD"/special_file_table_kernel.txt 
/dev		d    755  0    0    -    -    -    -    -
/dev/console	c    600  0    0    5    1    0    0    -
/dev/ptmx	c    666  0    0    5    2    0    0    -
/dev/null	c    666  0    0    1    3    0    0    -
/dev/mem	c    640  0    0    1    1    0    0    -
/dev/tty0	c    666  0    0    4    0    0    -    -
/dev/tty1	c    666  0    0    4    1    0    -    -
/dev/tty2	c    666  0    0    4    2    0    -    -
/dev/tty3	c    666  0    0    4    3    0    -    -
/dev/tty4	c    666  0    0    4    4    0    -    -
/dev/tty5	c    666  0    0    4    5    0    -    -
/root		d    700  0    0    -    -    -    -    -
/tmp		d    777  0    0    -    -    -    -    -
/sys		d    755  0    0    -    -    -    -    -
/proc		d    755  0    0    -    -    -    -    -
/mnt		d    755  0    0    -    -    -    -    -
/var		d    755  0    0    -    -    -    -    -
/var/log	d    755  0    0    -    -    -    -    -
/var/cache	d    755  0    0    -    -    -    -    -
/var/run	d    755  0    0    -    -    -    -    -
EOF

#######################################################################
## Create base rootfs tree
#######################################################################
rsync -a files/ "$ROOTFS/"
if [ -d "$CONFIG/files" ]; then
	echo "#### Installing overrides"
	(cd "$CONFIG/files"; tar cf - .)|(cd "$ROOTFS"; tar xf -)
fi

#######################################################################
## Default "build" phases Definitions -- for Autoconf targets
#######################################################################
configure-generic-local() {
	local ret=0 ; set -x
	if [ ! -f configure ]; then
		if [ -f autogen.sh ]; then
			./autogen.sh \
				--prefix="$PACKAGE_PREFIX"
		elif [ -f configure.ac ]; then
			autoreconf;libtoolize;automake --add-missing
		fi
	fi
	if [ -f configure ]; then
		./configure \
			--build=$(uname -m) \
			--host=$TARGET_FULL_ARCH \
			--prefix="$PACKAGE_PREFIX" \
			"$@" || ret=1
	else
		echo Nothing to configure 
	fi
	set +x ;return $ret
}
configure-generic() {
	configure configure-generic-local "$@"
	set +x
}
compile-generic() {
	compile $MAKE -j8 $MAKE_CLEAN "$@"
}
#######################################################################
## The install default handler tries to fix libtool stupiditiew
#######################################################################
install-generic-local() {
	local destdir=$(hget destdir $PACKAGE)
	local makei="installwatch -o ._dist $MAKE install"
	case "$destdir" in
		none) $makei "$@" ;;
		"") $makei DESTDIR="$STAGING" "$@" ;;
		*) $makei DESTDIR="$destdir" "$@" ;;
	esac
	lafiles=$(awk '{if ($2 == "open" && match($3,/.la$/)) print $3;}' ._dist)
	for n in $lafiles; do
		echo LDCONFIG PATCH $n
		sed -i -e "s|\([ ']\)/usr|\1$STAGING_USR|g" $n
	done
}
install-generic() {
	log_install install-generic-local "$@"
}
deploy-generic() {
	return 0
}

# shell handler allows dropping the user in an interactive shell
# you you call ./minifsbuild <package>_shell
shell-generic() {
	echo "--- Entering interactive shell mode; type control D to exit"
	echo "    Environment is set so make & stuff should cross compile."
	echo "    This is BASH by the way, so you inherit the functions."
	echo "    " $(pwd)
	exec /bin/bash
}

#######################################################################
## Find out which package we want/have, and order them by build order
#######################################################################
PROCESS_PACKAGES=""
for pack in $PACKAGES; do 
	# check to see if that package was requested, otherwise, skip it
	dobuild=0
	for can in $BUILD_PACKAGES; do
		if [ "$can" = "$pack" ]; then
			dobuild=1; break
		fi
	done
	if [ $dobuild -eq 0 ]; then continue; fi
	PROCESS_PACKAGES+=" $pack"
done

# echo "Will build :" $PROCESS_PACKAGES

#######################################################################
## Build each packages
## 
## We don't do the 'deploy' phase in this pass, so they get all
## grouped later in the following pass
#######################################################################

export DEFAULT_PHASES="configure compile install deploy"

for pack in $PROCESS_PACKAGES; do 	
	dir=$(hget dir $pack)
	dir=${dir:-$pack}
	# echo PACK $pack dir $dir
	if [ -d "$BUILD/$dir" ]; then
		package $pack $dir
			phases=$(hget phases $pack)
			phases=${phases:-$DEFAULT_PHASES}

			if [ "$COMMAND_PACKAGE" = "$PACKAGE" ]; then
				ph=$COMMAND_TARGET
				case "$ph" in
					shell|rebuild|clean)
						optional-one-of \
							$TARGET_BOARD-$ph-$pack \
							$ph-$pack \
							$ph-generic || break
						;;
				esac
			fi
			
			for ph in $phases; do
				if [[ $ph == "deploy" ]]; then continue ;fi
				optional-one-of \
					$TARGET_BOARD-$ph-$pack \
					$ph-$pack \
					$ph-generic || break
			done
		end_package
	fi
done

#######################################################################
## Now, run the deploy phases for packages that wanted it
#######################################################################
echo "Deploying packages"
# this pass does just the 'deploy' bits
for pack in $PROCESS_PACKAGES; do 	
	dir=$(hget dir $pack)
	dir=${dir:-$pack}
	# echo PACK $pack dir $dir
	if [ -d "$BUILD/$dir" ]; then
		package $pack $dir
			phases=$(hget phases $pack)
			phases=${phases:-$DEFAULT_PHASES}
			
			for ph in $phases; do
				if [[ $ph != "deploy" ]]; then continue ;fi
				optional-one-of \
					$TARGET_BOARD-$ph-$pack \
					$ph-$pack \
					$ph-generic || break
			done
		end_package
	fi
done

# in minifs-script
optional board_compile

# in minifs-script
optional board_finish

chmod 0644 "$BUILD"/*.img "$BUILD"/*.ub 2>/dev/null
