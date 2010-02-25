
PACKAGES+=" filesystems"
FILESYSTEMS="filesystem-prepack"

hset url filesystems "none"

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
hset dir filesystem-ext "."
hset phases filesystem-ext "deploy"
hset dir filesystem-jffs "."
hset phases filesystem-jffs "deploy"

deploy-filesystem-prepack() {
	deploy "${CROSS}-strip" "$ROOTFS"/bin/* "$ROOTFS"/sbin/* "$ROOTFS"/usr/bin/* \
		2>/dev/null
	for lib in "$ROOTFS"/lib "$ROOTFS"/usr/lib; do
		if [ -d "$lib" ]; then
			find "$lib" -type f -exec "${CROSS}-strip" \
				--strip-unneeded {} \; \
					>>"$LOGFILE" 2>&1
		fi
	done
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
	if genext2fs -d "$ROOTFS" \
		-U \
		-D "$BUILD"/special_file_table.txt \
		-b ${TARGET_FS_EXT_SIZE:-8192} \
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


