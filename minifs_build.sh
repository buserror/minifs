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

set +o posix #needed for dashes in function names
set -m # enable job control

MINIFS_BOARD=${MINIFS_BOARD:-"atom"}

MINIFS_BOARD_COMP=""
for pd in $(echo "$MINIFS_BOARD"| tr "-" "\n") ; do
	MINIFS_BOARD_COMP="$pd:$MINIFS_BOARD_COMP"
done

# MINIFS_PATH contains collumn separated directories with extra
# package directories
# MINIFS_PACKAGES contains a list of space separated packaged to add

# if you want a .dot and .pdf file with all the .elf dependencies
# in your build folder, add this to your environment, you'll need
# GraphViz obviously 
# export CROSS_LINKER_DEPS=1

COMMAND=$1
COMMAND_PACKAGE=${COMMAND/_*}
COMMAND_TARGET=$2
COMMAND_TARGET=${COMMAND_TARGET:-${COMMAND/*_}}

echo MINIFS_BOARD $MINIFS_BOARD $COMMAND_TARGET $COMMAND_PACKAGE

BASE="$(pwd)"
export MINIFS_BASE="$BASE"

NEEDED_HOST_COMMANDS="make tar rsync installwatch wget git"

export BUILD="$BASE/build-${MINIFS_BOARD}"
CONF_BASE="$BASE/conf"
PATCHES="$CONF_BASE"/patches

export STAGING="$BUILD/staging"
export STAGING_USR="$STAGING/usr"
export ROOTFS="$BUILD/rootfs"
export ROOTFS_PLUGINS=""
export ROOTFS_KEEPERS="libnss_dns.so.2:libnss_dns-2.10.2.so:"
export STAGING_TOOLS="$BUILD"/staging-tools
KERNEL="$BUILD/kernel"
CONFIG="$CONF_BASE/board/$MINIFS_BOARD"
 
source "$CONF_BASE"/minifs-script-utils.sh
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
MAKE_ARGUMENTS="-j10"
CROSSTOOL_JOBS=".8"

mkdir -p "$STAGING_TOOLS"/bin
mkdir -p download "$KERNEL" "$ROOTFS" "$STAGING_USR" "$TOOLCHAIN"
mkdir -p "$STAGING_USR"/share/aclocal
mkdir -p /tmp/installwatch

# Always regenerate the rootfs
rm -rf "$ROOTFS"/*

TARGET_INITRD=${TARGET_INITRD:-0}
TARGET_FS_SQUASH=${TARGET_FS_SQUASH:-0}
TARGET_FS_EXT=${TARGET_FS_EXT:-1}
# only set this if you /know/ the parameters for your NAND
# TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"

# use shared libraries ? overridable in the target's scripts
TARGET_SHARED=0

# compile the "tools" for the host
( 	set -x
	make -C "$CONF_BASE"/host-tools DESTDIR="$STAGING_TOOLS" 
) >"$BUILD"/._tools.log 2>&1 || \
	( echo '## Unable to build tools :'; cat  "$BUILD"/._tools.log; exit 1 ) || exit 1
rm -f /tmp/pkg-config.log
if [ "$COMMAND" == "tools" ]; then exit ;fi

hset busybox version "1.19.2"
hset linux version "2.6.32.2"
hset crosstools version "1.13.0"

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
export LIBC_CFLAGS="${TARGET_LIBC_CFLAGS:-$TARGET_CFLAGS}"
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
# Modern crosstools needs all these too!
NEEDED_HOST_COMMANDS+=" svn cvs svn lzma"

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
for pd in "$CONF_BASE/packages" "$CONFIG/packages" $(minifs_path_split "packages"); do
	if [ -d "$pd" ]; then
		package_files+="$(echo $pd/*.sh) "
	fi
done
package_files=$(filename_sort $package_files)
#echo $package_files

fid=0
for p in $package_files; do 
	name=$(basename $p)
	order=$(expr match "$name" '0*\([0-9]*\)')
#	echo $p $order
	filid=$(((order * 1000) + fid))
	fid=$((fid + 1))
	package_set_group $filid
	source $p
done

# Add the list of external packages
TARGET_PACKAGES+=" $MINIFS_PACKAGES"
TARGET_PACKAGES+=" filesystems"

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
	dump_depends
	exit
fi

#######################################################################
## Take all the selected packages, and add their dependencies
## This loops until none of the packages add any more.
#######################################################################
export TARGET_PACKAGES
while true; do
	changed=0; newlist=""
	for wpack in $TARGET_PACKAGES; do 
		targets=$(hget $wpack targets)
		targets=${targets:-$wpack}
		for pack in $targets; do
			deps=$(hget $pack depends)
			for d in $deps; do
				if ! env_contains TARGET_PACKAGES $d; then
				#	echo ADD $pack depends on $d
					TARGET_PACKAGES+=" $d"; changed=1
				fi
			done
		done
	done
	if [ $changed -eq 0 ]; then break; fi
done

#######################################################################
## Give a chance to each package to cry for help, before downloading
#######################################################################
HOSTCHECK_FAILED=0
for package in $TARGET_PACKAGES; do 
	PACKAGE=$package
	optional_one_of \
		$MINIFS_BOARD-hostcheck-$package \
		hostcheck-$package || break
	unset PACKAGE
done
if [ $HOSTCHECK_FAILED == 1 ]; then exit 1; fi
unset PACKAGE

#######################################################################
## Download the files, unpack, and patch them
#######################################################################
pushd download >/dev/null
for package in $TARGET_PACKAGES; do 
	fil=$(hget $package url)

	if [ "$fil" = "" ]; then continue ; fi

	# adds the list of targets provided by this package
	# to the list of the ones we want to build
	targets=$(hget $package targets)
	BUILD_PACKAGES+=" ${targets:-$package}"
	
	if [ "$fil" = "none" ]; then  continue ; fi
	
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
			*) $WGET "$fil" -O "$loc" || { rm -f "$loc"; exit 1; } ;;
		esac
	fi
	baseroot=$package
	PACKAGE=$baseroot
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
		( for pd in \
				"$CONFIG/$baseroot" "$CONFIG/$baseroot$vers"\
				"$PATCHES/$baseroot" "$PATCHES/$baseroot$vers"\
				$(minifs_path_split "patches/$baseroot") \
				$(minifs_path_split "patches/$baseroot$vers"); do
			echo trying patches $pd
			if [ -d "$pd" ]; then
				echo "#### Patching $base"
				pushd "$BUILD/$baseroot"
					for pf in "$pd/"/*.patch; do
						echo "     Applying $pf"
						cat $pf | patch --merge -t -p1
					done
				popd
			fi
		done 
		pushd "$BUILD/$baseroot"
		echo Trying optional_one_of $MINIFS_BOARD-patch-$baseroot patch-$baseroot 
		optional_one_of \
			$MINIFS_BOARD-patch-$baseroot \
			patch-$baseroot || break
		) >"$BUILD/$baseroot/._patch_$baseroot.log" 2>&1
	fi
done
unset PACKAGE
popd >/dev/null

if [ "$COMMAND" == "unpack" ]; then exit ; fi

#######################################################################
## Create base rootfs tree
#######################################################################
for pd in "$CONF_BASE/rootfs-base"; do
	if [ -d "$pd" ]; then
		rsync -a "$pd/" "$ROOTFS/"
	fi
done

#######################################################################
## Default "build" phases Definitions -- for Autoconf targets
#######################################################################
configure-generic-local() {
	local ret=0 ; set -x
	local sysconf=$(hget $PACKAGE sysconf)
	sysconf=${sysconf:-/etc}
	if [ ! -f configure ]; then
		if [ -f autogen.sh ]; then
			./autogen.sh \
				--build=$(uname -m) \
				--host=$TARGET_FULL_ARCH \
				--prefix="$PACKAGE_PREFIX" \
				--sysconfdir=$sysconf
		elif [ -f configure.ac -o -f configure.in ]; then
			aclocal && libtoolize --copy --force --automake 
			autoreconf --force #;libtoolize;automake --add-missing
		fi
	fi
	if [ -f configure ]; then
		./configure \
			--build=$(uname -m) \
			--host=$TARGET_FULL_ARCH \
			--prefix="$PACKAGE_PREFIX" \
			--sysconfdir=$sysconf \
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
	local extra=$(hget $PACKAGE compile)
	compile $MAKE $MAKE_ARGUMENTS $MAKE_CLEAN $extra "$@"
}

#######################################################################
## The install default handler tries to fix libtool stupidities
#######################################################################
install-generic-local() {
	local destdir=$(hget $PACKAGE destdir)
	local makei="installwatch -r /tmp/installwatch -d /tmp/installwatch/debug -o ._dist_$PACKAGE.log $MAKE install"
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
	# Check to see if there are lame comfig scripts around
	scr=$(hget $PACKAGE configscript)
	if [ "$scr" != "" ]; then
		for sc in "$STAGING_USR"/bin/$scr "$STAGING"/bin/$scr; do 
			if [ -x "$sc" ]; then
				sed -e "s|=/usr|=$STAGING_USR|g" \
					-e "s|=\"/usr|=\"$STAGING_USR|g" "$sc" \
						>"$STAGING_TOOLS"/bin/$scr && \
					chmod +x "$STAGING_TOOLS"/bin/$scr
				break;
			fi
		done
	fi
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
DEPLIST=""
export BUILD_PACKAGES
for pack in $PACKAGES; do 
	# check to see if that package was requested, otherwise, skip it
	dobuild=0
	if env_contains BUILD_PACKAGES $pack; then
		PROCESS_PACKAGES+=" $pack"
		DEPLIST+=" $pack($(hget $pack depends) $(hget $pack optional))"
	fi
done

#######################################################################
## Call the dependency sorter, and get back the result
#######################################################################
#echo DEPLIST $DEPLIST
PROCESS_PACKAGES=$(echo $DEPLIST|depsort 2>/tmp/depsort.log)
#echo PROCESS_PACKAGES $PROCESS_PACKAGES
#exit

#######################################################################
## Build each packages
## 
## We don't do the 'deploy' phase in this pass, so they get all
## grouped later in the following pass
#######################################################################

export DEFAULT_PHASES="setup configure compile install deploy"

process_one_package() {
	local package=$1
	local phases=$2
	for ph in $phases; do
		if [[ $ph == "deploy" ]]; then continue ;fi
		optional_one_of \
			$MINIFS_BOARD-$ph-$pack \
			$ph-$pack \
			$ph-generic || break
	done
}

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
						optional_one_of \
							$MINIFS_BOARD-$ph-$pack \
							$ph-$pack \
							$ph-generic || break
						;;
				esac
			fi
			process_one_package $pack "$phases"
		end_package
	fi
done

# Wait for every jobs to have finished
while true; do fg 2>/dev/null || break; done

#######################################################################
## Now, run the deploy phases for packages that wanted it
#######################################################################
echo "Deploying packages"
# this pass does just the 'deploy' bits
for pack in $PROCESS_PACKAGES; do 	
	dir=$(hget $pack dir)
	dir=${dir:-$pack}
	if [ -d "$BUILD/$dir" ]; then
		package $pack $dir
			phases=$(hget $pack phases)
			phases=${phases:-$DEFAULT_PHASES}
			
			for ph in $phases; do
				if [[ $ph != "deploy" ]]; then continue ;fi
				optional_one_of \
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
