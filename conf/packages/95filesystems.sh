

if [ $TARGET_SHARED -eq 1 ]; then
	PACKAGES+=" sharedlibs"
	TARGET_PACKAGES+=" sharedlibs"
fi

hset sharedlibs url "none"
hset sharedlibs dir "."
hset sharedlibs phases "deploy"
hset sharedlibs exclude "ldscripts:"

sharedlibs-rsync() {
	local excl=$(hget sharedlibs exclude)
	local extras=""

	for pd in $(echo "$excl"| tr ":" "\n") ; do
		if [ "$pd" != "" ]; then
			extras+="--exclude=$pd "
		fi
	done
	echo EXTRAS rsync $extras
	rsync -av \
		--chmod=u=rwX \
		--exclude=ldscripts \
		--exclude=._\* \
		--exclude=\*.o \
		--exclude=\*.map \
		--exclude=\*.spec \
		--exclude=\*.h \
		--exclude=\*.a --exclude=\*.la --exclude=\*.lai \
		--exclude=\*T \
		--exclude pkgconfig \
		$extras \
		$*
}
deploy-sharedlibs-local() {
	set -x
	mkdir -p "$ROOTFS/lib/" "$ROOTFS/usr/lib/"
	local exclude="  "
	local didit="";
	if [[ $CROSS_BASE ]]; then
		for sysroot in sysroot sys-root; do
			if [ ! -d "$CROSS_BASE/$TARGET_FULL_ARCH"/$sysroot ]; then
				continue;
			fi
			didit=1
			sharedlibs-rsync --exclude=\*.py \
				"$CROSS_BASE/$TARGET_FULL_ARCH"/$sysroot/lib/ \
				"$ROOTFS/lib/"
			sharedlibs-rsync --exclude=\*.py \
				"$CROSS_BASE/$TARGET_FULL_ARCH"/$sysroot/usr/lib/ \
				"$ROOTFS/usr/lib/"
		done
		# not a sysroot toolchain, so we need to copy the whole lib directory
		if [[ ! $didit ]]; then
			sharedlibs-rsync --exclude=\*.py \
				"$CROSS_BASE/$TARGET_FULL_ARCH"/lib/ \
				"$ROOTFS/lib/"
		fi
	fi
	sharedlibs-rsync \
		--exclude=\*.sh \
		--exclude ct-ng\* \
		"$STAGING_USR/lib/" \
		"$ROOTFS/usr/lib/"
	if [ "$TARGET_ARCH" = "x86_64" ]; then
		ln -s -f lib "$ROOTFS"/lib64
		ln -s -f lib "$ROOTFS"/usr/lib64
	fi
	local dangling=$(find "$ROOTFS" -name \*.so -type f|grep -v '\-[0-9]')
#	if [ "$dangling" != "" ]; then rm -f $dangling; fi
	echo THESE ARE DANGLING LINKS: $danglings
	optional $MINIFS_BOARD-sharedlibs-cleanup
	set +x
}
deploy-sharedlibs() {
	echo "    Installing shared libraries"
	touch "._install_$PACKAGE"
	deploy deploy-sharedlibs-local
}

PACKAGES+=" filesystem-prepack"
hset filesystem-prepack url "none"

PACKAGES+=" filesystems"
hset filesystems url "none"
hset filesystems dir "."
hset filesystems depends "busybox sharedlibs filesystem-populate filesystem-prepack"
hset filesystems phases "deploy"
FILESYSTEMS=""

if [ $TARGET_FS_SQUASH -eq 1 ]; then
	FILESYSTEMS+=" filesystem-squash"
	NEEDED_HOST_COMMANDS+=" mksquashfs"
fi
if [ $TARGET_FS_EXT -eq 1 ]; then
	FILESYSTEMS+=" filesystem-ext"
	NEEDED_HOST_COMMANDS+=" genext2fs tune2fs"
fi
if [ "$TARGET_FS_TAR" != "" ]; then
	FILESYSTEMS+=" filesystem-tar"
	NEEDED_HOST_COMMANDS+=" tar"
fi
if [ "$TARGET_FS_JFFS2" != "" ]; then
	FILESYSTEMS+=" filesystem-jffs"
	NEEDED_HOST_COMMANDS+=" mkfs.jffs2"
fi
if [ "$TARGET_FS_INITRD" != "" ]; then
	FILESYSTEMS+=" filesystem-initrd"
fi

PACKAGES+=" $FILESYSTEMS"
hset filesystems targets " filesystems $FILESYSTEMS"

hset filesystem-prepack dir "."
hset filesystem-prepack phases "setup deploy"
hset filesystem-squash dir "."
hset filesystem-squash phases "setup deploy"
hset filesystem-squash depends "filesystems"
hset filesystem-ext dir "."
hset filesystem-ext phases "deploy"
hset filesystem-ext depends "filesystems"
hset filesystem-tar dir "."
hset filesystem-tar phases "deploy"
hset filesystem-tar depends "filesystems"
hset filesystem-jffs dir "."
hset filesystem-jffs phases "deploy"
hset filesystem-jffs depends "filesystems"
hset filesystem-initrd dir "linux-obj"
hset filesystem-initrd phases "deploy"
hset filesystem-initrd depends "filesystems"

MINIFS_CROSS_STRIP="${CROSS}-strip"
MINIFS_STRIP=sstrip

setup-filesystem-prepack() {
	echo setup-filesystem-prepack
#######################################################################
# Create the text files used to make the device files in ROOTFS
# the count parameter can't be used because of mksquashfs
# name    	type mode uid gid major minor start inc count
#######################################################################
cat << EOF >"$STAGING_TOOLS"/special_file_table.txt
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
	if [ "$FS_SPECIAL_FILES" != "" ]; then
		echo "$FS_SPECIAL_FILES" | tr ":" "\n" >>"$STAGING_TOOLS"/special_file_table.txt
	fi
	cat "$STAGING_TOOLS"/special_file_table.txt | \
		awk '{nod=$2=="c"||$2=="b";print nod?"nod":"dir",$1,"0"$3,$4,$5, nod? $2" "$6" "$7:"";}' \
			>"$STAGING_TOOLS"/special_file_table_kernel.txt
}

deploy-filesystem-prepack() {
	deploy echo Copying
	echo -n "     Packing filesystem... "
	(
	export CROSS_LINKER_INVOKE="$TMPDIR/cross_linker_run.sh"
	cross_linker --purge || {
		echo "### cross_linker error, debug with $CROSS_LINKER_INVOKE"
		exit 1
	}
	# Use MINIFS_NOSTRIP=1 for an unstripped rootfs
	# Use MINIFS_NOSTRIP='regex' to prevent the files matching regex
	# to be stripped
	if [ "$MINIFS_NOSTRIP" != "1" ]; then
		local strip=$(ls "$ROOTFS"/bin/* "$ROOTFS"/sbin/* \
			"$ROOTFS"/usr/bin/* "$ROOTFS"/usr/sbin/* \
			| egrep -v "${MINIFS_NOSTRIP-''}")
		$MINIFS_STRIP $strip 2>/dev/null
		for lib in "$ROOTFS"/lib "$ROOTFS"/usr/lib; do
			if [ -d "$lib" ]; then
				strip=$(find "$lib" -type f \
				| egrep -v "${MINIFS_NOSTRIP-''}")
				$MINIFS_CROSS_STRIP --strip-unneeded $strip || true
			fi
		done
	fi
	) >>"$LOGFILE" 2>&1 || {
		echo "FAILED"; exit 1
	}
	echo "Done"
}

setup-filesystem-squash() {
	echo setup-filesystem-squash
	cat "$STAGING_TOOLS"/special_file_table.txt |
		awk '{print $1,$2,$3,$4,$5,$6,$7}' |
		sed 's/[- ]*$//g' >"$STAGING_TOOLS"/special_file_table_squash.txt
}

deploy-filesystem-squash() {
	local out="$BUILD"/minifs-full-squashfs.img
	echo -n "     Building $out "
	rm -f "$out"
	if declare -F $MINIFS_BOARD-create-manifest-file >/dev/null; then
		# The parameter "0" makes the script create a manifest file
		# that's included in the minifs image and resides in the
		# "/etc" folder on the target.
		$MINIFS_BOARD-create-manifest-file 0
	fi
	if mksquashfs "$ROOTFS" "$out" $(hget filesystem-squash options) \
		-all-root \
		-pf "$STAGING_TOOLS"/special_file_table_squash.txt \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		echo Done
	else
		echo "#### ERROR"
	fi
}

deploy-filesystem-ext() {
	if [ $TARGET_FS_EXT -eq 0 ]; then
		return
	fi
	echo "TARGET_FS_EXT $TARGET_FS_EXT"
	local out="$BUILD"/minifs-full-ext.img
	echo -n "     Building $out "
	local basesize=$(du -s "$ROOTFS"|awk '{print $1;}')
	#local size=${TARGET_FS_EXT_SIZE:-8192}
	local size=$(((($basesize*3)/2)&~512))
	if (($size < 4096)); then size=4096; fi
	echo -n "$basesize/$size "
	if genext2fs -d "$ROOTFS" \
		-m 0 -U -i $(($size / 10)) \
		-D "$STAGING_TOOLS"/special_file_table.txt \
		-b $size \
		"$out" \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		tune2fs -j "$out" \
			>>"$BUILD/._filesystem.log" 2>&1
		echo Done
	else
		echo "#### ERROR"
	fi
}

deploy-filesystem-tar() {
	local out="$BUILD"/minifs-full.tar.gz
	echo -n "     Building $out "
	if tar zcf $out -C "$ROOTFS" ./ \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		echo Done
	else
		echo "#### ERROR"
	fi
}

hostcheck-filesystem-jffs() {
	hostcheck_commands mkfs.jffs2
}

deploy-filesystem-jffs() {
	local out="$BUILD"/minifs-full-jffs2.img
	echo -n "     Building $out "
	if mkfs.jffs2 $TARGET_FS_JFFS2 \
		-r "$ROOTFS" \
		-o "$out"  \
		-D "$STAGING_TOOLS"/special_file_table.txt \
			>>"$BUILD/._filesystem_jffs.log" 2>&1 ; then
		echo Done
	else
		echo "#### ERROR Generating " "$BUILD"/minifs-full-jffs2.img
	fi
}

# Set TARGET_FS_INITRD to whatever format you want, remember to activate
# that format in the kernel config. Known to work are 'lzma' 'gz' etc
deploy-filesystem-initrd() {
	local out="$BUILD"/minifs-full-initrd.$TARGET_FS_INITRD
	echo -n "     Building $out "
	if sh ../linux/scripts/gen_initramfs_list.sh \
		-o "$out" \
		"$STAGING_TOOLS"/special_file_table_kernel.txt ../rootfs \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		echo Done
	else
		echo "#### ERROR"
	fi
}


