
if [ $TARGET_SHARED -eq 1 ]; then
	PACKAGES+=" sharedlibs"	
	TARGET_PACKAGES+=" sharedlibs"
fi

hset url sharedlibs "none" 
hset dir sharedlibs "."
hset phases sharedlibs "deploy"
hset depends sharedlibs "systemlibs"

deploy-sharedlibs() {
	deploy echo Copying
	rm -f $LOGFILE
	mkdir -p "$ROOTFS/lib/" "$ROOTFS/usr/lib/"
	echo "    Nearly there, Installing Staging binaries"
	(
	echo Creating "$ROOTFS/lib/"
	rsync -av \
		--exclude=\*.a --exclude=\*.la \
		--exclude pkgconfig \
		"$STAGING/lib/" \
		"$ROOTFS/lib/"
	echo Creating "$ROOTFS/usr/lib/" 
	rsync -av \
		--exclude=\*.a --exclude=\*.la \
		--exclude=\*.sh \
		--exclude pkgconfig \
		--exclude ct-ng\* \
		"$STAGING_USR/lib/" \
		"$ROOTFS/usr/lib/" 

	optional $TARGET_BOARD-sharedlibs-cleanup
	) >>"$LOGFILE" 2>&1
	# removes non-accessed libraries. We want the errors here
	(
	# export CROSS_LINKER_INVOKE="/tmp/cross_linker_run.sh"
	cross_linker --purge
	) >>"$LOGFILE"
}
