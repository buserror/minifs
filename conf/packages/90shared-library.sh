
if [ $TARGET_SHARED -eq 1 ]; then
	PACKAGES+=" sharedlibs"	
	TARGET_PACKAGES+=" sharedlibs"
fi

hset sharedlibs url "none"
hset sharedlibs dir "."
hset sharedlibs phases "deploy"

deploy-sharedlibs-local() {
	mkdir -p "$ROOTFS/lib/" "$ROOTFS/usr/lib/"
	echo Creating "$ROOTFS/lib/"
	rsync -av \
		--chmod=u=rwX \
		--exclude=\*.a --exclude=\*.la --exclude=\*.lai \
		--exclude pkgconfig \
		"$CROSS_BASE/$TARGET_FULL_ARCH"/sysroot/lib/ \
		"$ROOTFS/lib/"
	echo Creating "$ROOTFS/usr/lib/" 
	rsync -av \
		--chmod=u=rwX \
		--exclude=\*.a --exclude=\*.la --exclude=\*.lai \
		--exclude pkgconfig \
		"$CROSS_BASE/$TARGET_FULL_ARCH"/sysroot/usr/lib/ \
		"$ROOTFS/usr/lib/"
	rsync -av \
		--chmod=u=rwX \
		--exclude=\*.a --exclude=\*.la --exclude=\*.lai \
		--exclude=\*.sh \
		--exclude pkgconfig \
		--exclude ct-ng\* \
		"$STAGING_USR/lib/" \
		"$ROOTFS/usr/lib/" 

	optional $MINIFS_BOARD-sharedlibs-cleanup
	# export CROSS_LINKER_INVOKE="/tmp/cross_linker_run.sh"
	cross_linker --purge
}

deploy-sharedlibs() {
	echo "    Nearly there, Installing shared libraries"
	touch "._install_$PACKAGE"
	deploy deploy-sharedlibs-local
}
