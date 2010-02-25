
if [ $TARGET_SHARED -eq 1 ]; then
	PACKAGES+=" sharedlibs"	
	TARGET_PACKAGES+=" sharedlibs"
fi

hset url sharedlibs "none" 
hset dir sharedlibs "."

deploy-sharedlibs() {
	mkdir -p "$ROOTFS/lib/" "$ROOTFS/usr/lib/"
	deploy echo Copying libraries
	rsync -av \
		--exclude=\*.a --exclude=\*.la \
		"$TOOLCHAIN/$TARGET_FULL_ARCH"/lib/ \
		"$ROOTFS/lib/" \
			>>"$LOGFILE" 2>&1 &&
	rsync -av \
		--exclude=\*.a --exclude=\*.la \
		--exclude pkgconfig \
		"$STAGING/lib/" \
		"$ROOTFS/usr/lib/" \
			>>"$LOGFILE" 2>&1 
}

configure-sharedlibs() {
	configure echo Done
}
compile-sharedlibs() {
	compile echo Done
}
install-sharedlibs() {
	install echo Done
}

