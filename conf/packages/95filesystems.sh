

#######################################################################
# Create the text files used to make the device files in ROOTFS
# the count parameter can't be used because of mksquashfs 
# name    	type mode uid gid major minor start inc count
#######################################################################
cat << EOF | tee "$STAGING_TOOLS"/special_file_table.txt |\
	awk '{nod=$2=="c"||$2=="b";print nod?"nod":"dir",$1,"0"$3,$4,$5, nod? $2" "$6" "$7:"";}' \
	>"$STAGING_TOOLS"/special_file_table_kernel.txt 
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

PACKAGES+=" filesystem-prepack"
hset filesystem-prepack url "none"

PACKAGES+=" filesystems"
hset filesystems url "none"
hset filesystems depends "busybox sharedlibs filesystem-populate filesystem-prepack"
FILESYSTEMS=""

if [ $TARGET_FS_SQUASH -eq 1 ]; then
	FILESYSTEMS+=" filesystem-squash"
	NEEDED_HOST_COMMANDS+=" mksquashfs"
fi
if [ $TARGET_FS_EXT -eq 1 ]; then
	FILESYSTEMS+=" filesystem-ext"
	NEEDED_HOST_COMMANDS+=" genext2fs tune2fs"
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
hset filesystem-prepack phases "deploy"
hset filesystem-squash dir "."
hset filesystem-squash phases "deploy"
hset filesystem-squash depends "filesystems"
hset filesystem-ext dir "."
hset filesystem-ext phases "deploy"
hset filesystem-ext depends "filesystems"
hset filesystem-jffs dir "."
hset filesystem-jffs phases "deploy"
hset filesystem-jffs depends "filesystems"
hset filesystem-initrd dir "linux-obj"
hset filesystem-initrd phases "deploy"
hset filesystem-initrd depends "filesystems"

MINIFS_CROSS_STRIP="${CROSS}-strip"
MINIFS_STRIP=sstrip

deploy-filesystem-prepack() {
	deploy echo Copying
	echo -n "     Packing filesystem... "
	(
	export CROSS_LINKER_INVOKE="/tmp/cross_linker_run.sh"
	cross_linker --purge || {
		echo "### cross_linker error, debug with $CROSS_LINKER_INVOKE"
		exit 1
	}

	$MINIFS_STRIP "$ROOTFS"/bin/* "$ROOTFS"/sbin/* \
		"$ROOTFS"/usr/bin/* "$ROOTFS"/usr/sbin/* \
		2>/dev/null
	for lib in "$ROOTFS"/lib "$ROOTFS"/usr/lib; do
		if [ -d "$lib" ]; then
			find "$lib" -type f -exec "${CROSS}-strip" \
				--strip-unneeded {} \; 
		fi
	done
	) >>"$LOGFILE" 2>&1 || {
		echo "FAILED"; exit 1
	}
	echo "Done"
}

deploy-filesystem-squash() {
	local out="$BUILD"/minifs-full-squashfs.img
	echo -n "     Building $out "
	if mksquashfs "$ROOTFS" "$out" \
		-all-root \
		-pf "$STAGING_TOOLS"/special_file_table.txt \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		echo Done
	else
		echo "#### ERROR"
	fi		
}

deploy-filesystem-ext() {
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

deploy-filesystem-jffs() {
	local out="$BUILD"/minifs-full-jffs2.img
	echo -n "     Building $out "
	if mkfs.jffs2 $TARGET_FS_JFFS2 \
		-r "$ROOTFS" \
		-o "$out"  \
		-D "$STAGING_TOOLS"/special_file_table.txt \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
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


