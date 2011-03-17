#!/bin/bash

# prerequisites : 
# libtool, bison, flex, genext2fs, squashfs, svn -- probably more
# u-boot-mkimage -- for the arm targets

#######################################################################
# 
# (C) Michel Pollet <buserror@gmail.com>
#
#######################################################################
#
# this is the board we are making. Several boards can co-exist, the
# toolchains are "compatible" and live in the toolchain/ subdirectory.
# Several board of the same arch can also coexist, sharing the same
# toolchain
#
#######################################################################
MINIFS_BOARD=${MINIFS_BOARD:-"atom"}
# MINIFS_PATH contains collumn separated directories with extra
# package directories
# MINIFS_PACKAGES contains a list of space separated packaged to add

# if you want a .dot and .pdf file with all the .elf dependencies
# in your build folder, add this to your environment, you'll need
# GraphViz obviously 
# export CROSS_LINKER_DEPS=1

COMMAND=$1
COMMAND_PACKAGE=${COMMAND/_*}
COMMAND_TARGET=${COMMAND/*_}

echo MINIFS_BOARD $MINIFS_BOARD $COMMAND

BASE="$(pwd)"
export MINIFS_BASE="$BASE"

NEEDED_HOST_COMMANDS="make tar rsync installwatch wget git"

export BUILD="$BASE/build-${MINIFS_BOARD}"
PATCHES="$BASE/conf"
export STAGING="$BUILD/staging"
export STAGING_USR="$STAGING/usr"
export ROOTFS="$BUILD/rootfs"
export ROOTFS_PLUGINS=""
export ROOTFS_KEEPERS="libnss_dns.so.2:libnss_dns-2.10.2.so:"
export STAGING_TOOLS="$BUILD"/staging-tools
KERNEL="$BUILD/kernel"
CONFIG="$PATCHES/board/$MINIFS_BOARD"
 
source "$PATCHES"/minifs-script-utils.sh
source "$CONFIG"/minifs-script.sh

# remove any package, and it's installed dirs
if [ "$COMMAND_TARGET" == "remove" ]; then
	remove_package $COMMAND_PACKAGE
	exit
fi

TOOLCHAIN="$BASE/toolchain"
TOOLCHAIN_BUILD="$BASE/build-toolchain"
CROSS_BASE="$TOOLCHAIN/$TARGET_FULL_ARCH/"
CROSS="$CROSS_BASE/bin/$TARGET_FULL_ARCH"
GCC="${CROSS}-gcc"

WGET=wget
MAKE=make
MAKE_ARGUMENTS="-j8"
CROSSTOOL_JOBS=".4"

mkdir -p "$STAGING_TOOLS"/bin
mkdir -p download "$KERNEL" "$ROOTFS" "$STAGING_USR" "$TOOLCHAIN"
mkdir -p "$STAGING_USR"/share/aclocal

# Always regenerate the rootfs
rm -rf "$ROOTFS"/*

TARGET_INITRD=${TARGET_INITRD:-0}
TARGET_FS_SQUASH=1
TARGET_FS_EXT=1
# only set this if you /know/ the parameters for your NAND
# TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"

# use shared libraries ? overridable in the target's scripts
TARGET_SHARED=0

# compile the "tools" for the host
( 	set -x
	make -C "$PATCHES"/host-tools DESTDIR="$STAGING_TOOLS" &&
	cd "$STAGING_TOOLS"/bin &&
	ln -f -s $(which libtool) "$TARGET_FULL_ARCH"-libtool
) >"$BUILD"/._tools.log 2>&1 || \
	( echo '## Unable to build tools :'; cat  "$BUILD"/._tools.log; exit 1 ) || exit 1
rm -f /tmp/pkg-config.log
if [ "$COMMAND" == "tools" ]; then exit ;fi

hset busybox version "1.18.4"
hset linux version "2.6.32.2"
hset crosstools version "1.10.0"

# PATH needs sbin (for depmod), the host tools, and the cross toolchain
export BASE_PATH="$PATH"
export PATH="$TOOLCHAIN/bin:$TOOLCHAIN/$TARGET_FULL_ARCH/bin:$BUILD/staging-tools/bin:/usr/sbin:/sbin:$PATH"

# ccfix is the prefixer for gcc that warns of "absolute" host paths
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
CONFIG_KERNEL_LZO=$(grep '^CONFIG_KERNEL_LZO=y' "$CONFIG/config_kernel.conf")
CONFIG_UCLIBC=$(grep 'CT_LIBC_UCLIBC_0_9_30_or_later=y' "$CONFIG/config_crosstools.conf")

if [ "$CONFIG_KERNEL_LZO" != "" ]; then
	NEEDED_HOST_COMMANDS+=" lzop"
fi

#######################################################################
# PACKAGES is the entire list of possible packages, as filled by the 
# conf/packages/*.sh scripts, in their ideal build order.
# TARGET_PACKAGES are the ones requested by the target build script, in any
# order
# BUILD_PACKAGES is the same, but with alias resolved so "linux" becomes
# "linux-headers", "linux-modules" etc.
# The script for the union of these and can then have a list of packages
# to build.
#######################################################################
export PACKAGES=""
export TARGET_PACKAGES="linux $NEED_CROSSTOOLS systemlibs busybox filesystems"
export BUILD_PACKAGES=""

# in minifs-script, optional
optional board_set_versions

#######################################################################
## Load all the package scripts
#######################################################################

package_files=""
for pd in "$PATCHES/packages" "$CONFIG/packages" $(minifs_path_split "packages"); do
	if [ -d "$pd" ]; then
		package_files+="$(echo $pd/*.sh) "
	fi
done
package_files=$(filename_sort $package_files)
#echo $package_files

for p in $package_files; do 
	source $p
done

# Add the list of external packages
TARGET_PACKAGES+=" $MINIFS_PACKAGES"

optional board_prepare

# verify we have all the commands we need to build on the host
check_host_commands

# if a local config file is found, run it, it allows quick
# testing of packages without changing the real board file etc
for sh in .config .config-$(hostname -s) .config-$MINIFS_BOARD; do
	if [ -f $sh ]; then
		source $sh
	fi
done

if [ "$TARGET_SHARED" -eq 0 ]; then
	echo "### Static build!!"
	LDFLAGS_BASE="-static $LDFLAGS_BASE"
fi
export LDFLAGS_RLINK="$LDFLAGS_BASE -Wl,-rpath -Wl,/usr/lib -Wl,-rpath-link -Wl,$STAGING/lib -Wl,-rpath-link -Wl,$STAGING_USR/lib"
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
		deps=$(hget $pack depends)
		for d in $deps; do
			isthere=0
			for look in $TARGET_PACKAGES; do 
				if [ "$d" = "$look" ]; then
					isthere=1; break
				fi
			done
			if [ $isthere -eq 0 ]; then
		#		echo ADD $pack depends on $d
				newlist+=" $d"; changed=1
			fi
		done
		newlist+=" $pack"
	done
	TARGET_PACKAGES=$newlist
	if [ $changed -eq 0 ]; then break; fi
done

#######################################################################
## Download the files, unpack, and patch them
#######################################################################
pushd download
for package in $TARGET_PACKAGES; do 
	fil=$(hget $package url)

	if [ "$fil" = "" ]; then continue ; fi

	# adds the list of targets provided by this package
	# to the list of the ones we want to build
	targets=$(hget $package targets)
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
	vers=$(echo $base|sed -r 's|.*([-_](v?[0-9]+[a-z]?[\._]?)+)\..*|\1|')
	#echo "base=$base typ=$typ loc=$loc vers=$vers"
	 
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
						rm -rf "$package.git" &&
						rm -rf "$BUILD/$package"
				fi
			;;
			svn)	if [ ! -d "$package.svn" ]; then
					echo "#### svn clone $url $package.git"
					svnopt=$(hget $package svnopt)
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
						rm -rf "$package.svn" &&
						rm -rf "$BUILD/$package"
				fi
			;;
			*) $WGET "$fil" -O "$loc" || exit 1 ;;
		esac
	fi
	baseroot=$package
	#echo $package = $fil
	# try to compare the URL to see if it changed, if so, remove
	# the old source and rebuild automagically
	if [ -f "$BUILD/$baseroot/._url" ]; then
		old=$(cat "$BUILD/$baseroot/._url")
		if [ "$fil" != "$old" ]; then
			echo "  ++  Rebuilding $baseroot "
			remove_package $baseroot
		fi 
	fi
	if [ ! -d "$BUILD/$baseroot" ]; then
		echo "####  Extracting $loc to $BUILD/$baseroot ($typ)"
		mkdir -p "$BUILD/$baseroot"
		echo "$fil" >"$BUILD/$baseroot/._url"
		echo "$vers" >"$BUILD/$baseroot/._version"
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
		for pd in \
				"$CONFIG/$baseroot" "$CONFIG/$baseroot$vers"\
				"$PATCHES/patches/$baseroot" "$PATCHES/patches/$baseroot$vers"\
				$(minifs_path_split "patches/$baseroot") \
				$(minifs_path_split "patches/$baseroot$vers"); do
			#echo trying patches $pd
			if [ -d "$pd" ]; then
				echo "#### Patching $base"
				( pushd "$BUILD/$baseroot"
					for pf in "$pd/"/*.patch; do
						echo "     Applying $pf"
						cat $pf | patch -t -p1
					done
				popd ) >"$BUILD/$baseroot/._patch_$baseroot.log"
			fi
		done
	fi
done
popd

if [ "$COMMAND" == "unpack" ]; then
	exit
fi

#######################################################################
## Create base rootfs tree
#######################################################################
for pd in "$PATCHES/rootfs-base" "$CONFIG/rootfs" $(minifs_path_split "rootfs"); do
	if [ -d "$pd" ]; then
		rsync -a "$pd/" "$ROOTFS/"
	fi
done

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
			autoreconf --force #;libtoolize;automake --add-missing
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
	compile $MAKE $MAKE_ARGUMENTS $MAKE_CLEAN "$@"
}

#######################################################################
## The install default handler tries to fix libtool stupidities
#######################################################################
install-generic-local() {
	local destdir=$(hget $PACKAGE destdir)
	local makei="installwatch -d /tmp/installwatch.debug -o ._dist_$PACKAGE.log $MAKE install"
	set -x
	case "$destdir" in
		none) $makei "$@" ;;
		"") $makei DESTDIR="$STAGING" "$@" ;;
		*) $makei DESTDIR="$destdir" "$@" ;;
	esac
	lafiles=$(awk '{if ($2 == "open" && match($3,/.la$/)) print $3;}' ._dist_$PACKAGE.log)
	for n in $lafiles; do
		echo LDCONFIG PATCH $n
		sed -i -e "s|\([ ']\)/usr|\1$STAGING_USR|g" $n
	done
	set +x
}
install-generic() {
	log_install install-generic-local "$@"
}
#######################################################################
# the default deploy phase does... nothing. Most packages are libraries
# and these are installed automaticaly in the target filesystem. The
# deploy phase is made only for the pakcages that want to install
# anything in the rootfs, like utils, etc, fonts etc etc
#######################################################################
deploy-generic() {
	return 0
}

#######################################################################
# shell handler allows dropping the user in an interactive shell
# when you call ./minifsbuild <package>_shell
#######################################################################
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

#echo TARGET_PACKAGES $TARGET_PACKAGES
#echo BUILD_PACKAGES $BUILD_PACKAGES
#echo "Will build :" $PROCESS_PACKAGES

#######################################################################
## Build each packages
## 
## We don't do the 'deploy' phase in this pass, so they get all
## grouped later in the following pass
#######################################################################

export DEFAULT_PHASES="setup configure compile install deploy"

for pack in $PROCESS_PACKAGES; do 	
	dir=$(hget $pack dir)
	dir=${dir:-$pack}
	# echo PACK $pack dir $dir
	if [ -d "$BUILD/$dir" ]; then
		package $pack $dir
			phases=$(hget $pack phases)
			phases=${phases:-$DEFAULT_PHASES}

			if [ "$COMMAND_PACKAGE" = "$PACKAGE" ]; then
				ph=$COMMAND_TARGET
				case "$ph" in
					shell|rebuild|clean)
						optional-one-of \
							$MINIFS_BOARD-$ph-$pack \
							$ph-$pack \
							$ph-generic || break
						;;
				esac
			fi
			
			for ph in $phases; do
				if [[ $ph == "deploy" ]]; then continue ;fi
				optional-one-of \
					$MINIFS_BOARD-$ph-$pack \
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
	dir=$(hget $pack dir)
	dir=${dir:-$pack}
	# echo PACK $pack dir $dir
	if [ -d "$BUILD/$dir" ]; then
		package $pack $dir
			phases=$(hget $pack phases)
			phases=${phases:-$DEFAULT_PHASES}
			
			for ph in $phases; do
				if [[ $ph != "deploy" ]]; then continue ;fi
				optional-one-of \
					$MINIFS_BOARD-$ph-$pack \
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
