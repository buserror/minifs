
PACKAGES+=" filesystems"
FILESYSTEMS="filesystem-prepack"

hset url filesystems "none"
hset depends filesystems "busybox sharedlibs"

if [ $TARGET_FS_SQUASH -eq 1 ]; then
	FILESYSTEMS+=" filesystem-squash"
fi

if [ $TARGET_FS_EXT -eq 1 ]; then
	FILESYSTEMS+=" filesystem-ext"
fi

if [ "$TARGET_FS_JFFS2" != "" ]; then
	FILESYSTEMS+=" filesystem-jffs"
fi

PACKAGES+=" $FILESYSTEMS"
hset targets filesystems "$FILESYSTEMS"

hset dir filesystem-prepack "."
hset phases filesystem-prepack "deploy"
hset dir filesystem-squash "."
hset phases filesystem-squash "deploy"
hset depends filesystem-squash "filesystem-prepack"
hset dir filesystem-ext "."
hset phases filesystem-ext "deploy"
hset depends filesystem-ext "filesystem-prepack"
hset dir filesystem-jffs "."
hset phases filesystem-jffs "deploy"
hset depends filesystem-jffs "filesystem-prepack"

deploy-filesystem-prepack() {
	deploy echo Copying
	(
	rsync -av \
		"$STAGING_USR/etc/" \
		"$ROOTFS/etc/"
	mv "$ROOTFS"/usr/etc/* "$ROOTFS"/etc/ 
	rm -rf "$ROOTFS"/usr/etc/ "$ROOTFS"/usr/var/
	ln -s ../etc $ROOTFS/usr/etc
	ln -s ../var $ROOTFS/usr/var
	echo minifs-$TARGET_BOARD >$ROOTFS/etc/hostname
	) >>"$LOGFILE" 2>&1
}

deploy-filesystem-squash() {
	if mksquashfs "$ROOTFS" "$BUILD"/minifs-full-squashfs.img \
		-all-root \
		-pf "$BUILD"/special_file_table.txt \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		echo "    " "$BUILD"/minifs-full-squashfs.img " Created"
	else
		echo "#### ERROR Generating " "$BUILD"/minifs-full-squashfs.img
	fi
}

deploy-filesystem-ext() {
	local size=${TARGET_FS_EXT_SIZE:-8192}
	if genext2fs -d "$ROOTFS" \
		-U -i $(($size )) \
		-D "$BUILD"/special_file_table.txt \
		-b $size \
		"$BUILD"/minifs-full-ext.img \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		$TUNEFS -j "$BUILD"/minifs-full-ext.img \
			>>"$BUILD/._filesystem.log" 2>&1
		echo "    " "$BUILD"/minifs-full-ext.img " Created"
	else		
		echo "#### ERROR Generating " "$BUILD"/minifs-full-ext.img
	fi
}

deploy-filesystem-jffs() {
	if mkfs.jffs2 $TARGET_FS_JFFS2 \
		-r "$ROOTFS" \
		-o "$BUILD"/minifs-full-jffs2.img  \
		-D "$BUILD"/special_file_table.txt \
			>>"$BUILD/._filesystem.log" 2>&1 ; then
		echo "    " "$BUILD"/minifs-full-jffs2.img " Created"
	else
		echo "#### ERROR Generating " "$BUILD"/minifs-full-jffs2.img
	fi		
}


