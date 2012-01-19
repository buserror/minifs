
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
	for sysroot in sysroot sys-root; do
		sharedlibs-rsync \
			"$CROSS_BASE/$TARGET_FULL_ARCH"/$sysroot/lib/ \
			"$ROOTFS/lib/"
		sharedlibs-rsync \
			"$CROSS_BASE/$TARGET_FULL_ARCH"/$sysroot/usr/lib/ \
			"$ROOTFS/usr/lib/"
	done
	sharedlibs-rsync \
		--exclude=\*.sh \
		--exclude ct-ng\* \
		"$STAGING_USR/lib/" \
		"$ROOTFS/usr/lib/" 
	if [ "$TARGET_ARCH" = "x86_64" ]; then
		ln -s -f lib "$ROOTFS"/lib64 
		ln -s -f lib "$ROOTFS"/usr/lib64 
	fi
	optional $MINIFS_BOARD-sharedlibs-cleanup
	set +x
}
deploy-sharedlibs() {
	echo "    Nearly there, Installing shared libraries"
	touch "._install_$PACKAGE"
	deploy deploy-sharedlibs-local
}
