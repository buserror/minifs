#######################################################################
## Jpeg
#######################################################################
PACKAGES="$PACKAGES jpegsrc"

#######################################################################
## mjpg-streamer
#######################################################################
PACKAGES="$PACKAGES mjpg"

configure-mjpg() {
	configure echo Done
}
compile-mjpg() {
	compile $MAKE CC="$GCC" \
		EXTRA_LDFLAGS="-L $STAGING/lib" \
		EXTRA_CFLAGS="-Os -I$STAGING/include $TARGET_CFLAGS" \
		STATIC=1
}
install-mjpg() {
	install cp -ra mjpg_streamer www "$ROOTFS"/bin/

	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	
	echo "* Starting mjpg_streamer..."
	/bin/mjpg_streamer -b -i "input_uvc.so -f 15 -r 960x720" -o "output_http.so -w /opt/www -p 80"
	EOF
	# now add the load module for the camera
	sed -i '
/^# LOAD MODULES/ a\
modprobe uvcvideo >/dev/null 2>&1
' "$ROOTFS"/etc/init.d/rcS
}
