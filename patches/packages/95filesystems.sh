
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
hset dir filesystem-squash "."
hset dir filesystem-ext "."
hset dir filesystem-jffs "."

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


#
# These aren't used
# 
configure-filesystem-prepack() {
	return 0
}
configure-filesystem-squash() {
	return 0
}
configure-filesystem-ext() {
	return 0
}
configure-filesystem-jffs() {
	return 0
}

compile-filesystem-prepack() {
	return 0
}
compile-filesystem-squash() {
	return 0
}
compile-filesystem-ext() {
	return 0
}
compile-filesystem-jffs() {
	return 0
}

install-filesystem-prepack() {
	log_install echo Done
}
install-filesystem-squash() {
	log_install echo Done
}
install-filesystem-ext() {
	log_install echo Done
}
install-filesystem-jffs() {
	log_install echo Done
}

