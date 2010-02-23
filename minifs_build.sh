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
# Next step is to load it! Only way for the moment is to use a SD card
# 
# (C) Michel Pollet <buserror@gmail.com>
# 

# this is the board we are making. Several boards can co-exist, the toolchains
# are "compatible" and live in the toolchain/ subdirectory. Several board of the
# same arch can also coexist, sharing the same toolchain
TARGET_BOARD="mini2440"

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

# 
# Download stuff, decompresses, install and patch
pushd download

VERSION_busybox=1.16.0
VERSION_linux=2.6.32.2
VERSION_crosstools=1.5.3

export PATH="$TOOLCHAIN/bin:$STAGING/bin:$PATH"
export CC="$TARGET_FULL_ARCH-gcc"
export CXX="$TARGET_FULL_ARCH-g++"

export CPPFLAGS="-I$STAGING/include" 
export LDFLAGS="-L$STAGING/lib"
export CFLAGS="-Os $TARGET_CFLAGS" 
export CXXFLAGS="$CFLAGS" 

export PKG_CONFIG_PATH="$STAGING/lib/pkgconfig"

# in minifs-script, optional
optional board_set_versions

url=(
	"http://busybox.net/downloads/busybox-${VERSION_busybox}.tar.bz2" 
	"http://www.kernel.org/pub/linux/kernel/v2.6/linux-${VERSION_linux}.tar.bz2" 
	"http://ymorin.is-a-geek.org/download/crosstool-ng/crosstool-ng-${VERSION_crosstools}.tar.bz2" 
	# useful and needed
	"http://www.zlib.net/zlib-1.2.3.tar.gz" 
	# screen doesn't work, work in progress
	#"http://ftp.gnu.org/gnu/screen/screen-4.0.3.tar.gz" 
	"http://dl.lm-sensors.org/i2c-tools/releases/i2c-tools-3.0.2.tar.bz2"
	# this can get compiled and installed im staging
	"http://kent.dl.sourceforge.net/project/libusb/libusb-0.1%20%28LEGACY%29/0.1.12/libusb-0.1.12.tar.gz"
	"http://www.intra2net.com/en/developer/libftdi/download/libftdi-0.16.tar.gz"
	#"http://ffmpeg.org/releases/ffmpeg-0.5.tar.bz2"
	"http://www.oberhumer.com/opensource/lzo/download/lzo-2.03.tar.gz"
	"http://heanet.dl.sourceforge.net/project/e2fsprogs/e2fsprogs/1.41.9/e2fsprogs-libs-1.41.9.tar.gz"
	"http://git.infradead.org/mtd-utils.git/snapshot/a67747b7a314e685085b62e8239442ea54959dbc.tar.gz#mtd_utils.tgz"
)
optional board_prepare

for fil in "${url[@]}" ; do
	proto=${fil/+*}
	fil=${fil/*+}
	base=${fil/*\//}
	typ=${fil/*.}
	url=${base/\#*}
	loc=${base/*#/}
	if [ ! -f "$loc" ]; then
		$WGET "$fil" -O "$loc"
	fi
	baseroot=${loc/-*/}
	baseroot=${baseroot/.*/}	
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

CONFIG_MODULES=$(grep '^CONFIG_MODULES=y' "$CONFIG/config_kernel.conf")

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

for pd in "$PATCHES/packages" "$CONFIG/packages" ; do
	if [ -d "$pd" ]; then
		echo "#### Loading $pd"
		for p in "$pd"/*.sh; do 
			source $p
		done
	fi
done

for pack in $PACKAGES; do 
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
