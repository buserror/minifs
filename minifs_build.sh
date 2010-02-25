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
# + Builds crosstools + uClibc
# + Builds and install busybox into rootfs/
# Then
# + Generates a ext3 base filesystem, ready to put on a SD/USB
# 	It is created small, but you can always use resize2fs to "fit"
# 	it to your partition size afterward.
# + Generates a compact squashfs filesystem
# Then
# + Builds the kernel proper.
# + Builds the "ramdisk" CPIO filesystem using the kernel method
# + Install the kernel+initrd combo file in build
# 
# The resulting kernel + initrd containing a pretty usefull system is 1.4MB
# 
# (C) Michel Pollet <buserror@gmail.com>
# 

# this is the board we are making. Several boards can co-exist, the toolchains
# are "compatible" and live in the toolchain/ subdirectory. Several board of the
# same arch can also coexist, sharing the same toolchain
TARGET_BOARD="yuckfan"

COMMAND=$1

BASE="$(pwd)"

BUILD="$BASE/build-${TARGET_BOARD}"
PATCHES="$BASE/patches"
STAGING="$BUILD/staging"
KERNEL="$BUILD/kernel"
ROOTFS="$BUILD/rootfs"
CONFIG="$PATCHES/conf-$TARGET_BOARD"

source "$PATCHES"/minifs-script-utils.sh
source "$CONFIG"/minifs-script.sh

TOOLCHAIN="$BASE/toolchain"
CROSS="$TOOLCHAIN/bin/$TARGET_FULL_ARCH"
GCC="${CROSS}-gcc"

TUNEFS=/sbin/tune2fs
WGET=wget
MAKE=make

# tell host pkgcomfig to find it's files there, not on the host
export PKG_CONFIG_PATH="$STAGING/lib/pkgconfig"

mkdir -p download "$KERNEL" "$ROOTFS" "$STAGING" "$TOOLCHAIN"

# Allways regenerate the rootfs
rm -rf "$ROOTFS"/* 

TARGET_INITRD=1
TARGET_FS_SQUASH=1
TARGET_FS_EXT=1
# only set this if you /know/ the parameters for your NAND
# TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"

# use shared libraries ?
TARGET_SHARED=0

PACKAGES=""

VERSION_busybox=1.16.0
VERSION_linux=2.6.32.2
VERSION_crosstools=1.5.3

export PATH="$TOOLCHAIN/bin:$PATH"
export CC="$TARGET_FULL_ARCH-gcc"
export CXX="$TARGET_FULL_ARCH-g++"

export CPPFLAGS="-I$STAGING/include" 
export LDFLAGS="-L$STAGING/lib"
export CFLAGS="-Os $TARGET_CFLAGS" 
export CXXFLAGS="$CFLAGS" 

export PKG_CONFIG_PATH="$STAGING/lib/pkgconfig"

CONFIG_MODULES=$(grep '^CONFIG_MODULES=y' "$CONFIG/config_kernel.conf")

export TARGET_PACKAGES="linux $NEED_CROSSTOOLS busybox filesystems"
export BUILD_PACKAGES=""

# in minifs-script, optional
optional board_set_versions

# load all the package files
for pd in "$PATCHES/packages" "$CONFIG/packages" ; do
	if [ -d "$pd" ]; then
		echo "#### Loading $pd"
		for p in "$pd"/*.sh; do 
			source $p
		done
	fi
done

# Download stuff, decompresses, install and patch
pushd download

optional board_prepare

for package in $TARGET_PACKAGES; do 
	fil=$(hget url $package)

	if [ "$fil" = "" ]; then 
		echo "##### package $package is unknown"
		exit 1
	fi
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
	url=${base/\#*}
	loc=${base/*#/}
	
	# maybe the package has a magic downloader ?
	optional download-$package

	if [ ! -f "$loc" ]; then
		$WGET "$fil" -O "$loc"
	fi
	baseroot=$package
	#echo $package = $fil
	if [ ! -d "$BUILD/$baseroot" ]; then
		echo "####  Extracting $loc to $BUILD/$baseroot ($typ)"
		mkdir -p "$BUILD/$baseroot"

		case "$typ" in
			bz2)	tar jx -C "$BUILD/$baseroot" --strip 1 -f "$loc"	;;
			gz|tgz)	tar zx -C "$BUILD/$baseroot" --strip 1 -f "$loc"	;;
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
/var/run	d    755  0    0    -    -    -    -    -
EOF

#######################################################################
## Build extra packages
#######################################################################

echo "#### Copying default rootfs files"
rsync -a files/ "$ROOTFS/"
if [ -d "$CONFIG/files" ]; then
	echo "#### Installing overrides"
	(cd "$CONFIG/files"; tar cf - .)|(cd "$ROOTFS"; tar xf -)
fi

configure-generic() {
	configure ./configure \
		--host=$TARGET_FULL_ARCH \
		--prefix="$STAGING"
}
compile-generic() {
	compile $MAKE -j8
}
install-generic() {
	log_install $MAKE install
}
deploy-generic() {
	return 0
}

#echo PACKAGES $PACKAGES
#echo BUILD_PACKAGES $BUILD_PACKAGES
for pack in $PACKAGES; do 
	# check to see if that package was requested, otherwise, skip it
	dobuild=0
	for can in $BUILD_PACKAGES; do
		if [ "$can" = "$pack" ]; then
			dobuild=1
			break
		fi
	done
	if [ $dobuild -eq 0 ]; then
		# echo Skipping $pack
		continue
	fi
	
	dir=$(hget dir $pack)
	dir=${dir:-$pack}
	if [ -d "$BUILD/$dir" ]; then
		package $dir
			PACKAGE=$pack
			optional-one-of \
				$TARGET_BOARD-configure-$pack \
				configure-$pack \
				configure-generic &&
			optional-one-of \
				$TARGET_BOARD-compile-$pack \
				compile-$pack \
				compile-generic &&
			optional-one-of \
				$TARGET_BOARD-install-$pack \
				install-$pack \
				install-generic	&&
			optional-one-of \
				$TARGET_BOARD-deploy-$pack \
				deploy-$pack \
				deploy-generic			
		end_package
	fi
done

# in minifs-script
optional board_compile

# in minifs-script
optional board_finish

chmod 0644 "$BUILD"/*.img "$BUILD"/*.ub 2>/dev/null
