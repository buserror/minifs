
#######################################################################
## mjpg-streamer
#######################################################################
PACKAGES+=" mjpg"

hset mjpg url "mjpg-streamer.tar.bz2"
hset mjpg depends "busybox libjpeg"

download-mjpg() {
	pushd "$DOWNLOAD"
	if [ ! -f "mjpg-streamer.tar.bz2" ]; then
			echo "####  Downloading SVN and creating tarball of mjpg-streamer"
			svn co "https://mjpg-streamer.svn.sourceforge.net/svnroot/mjpg-streamer/mjpg-streamer" &&
			tar jcf mjpg-streamer.tar.bz2 mjpg-streamer &&
			rm -rf mjpg-streamer
	fi
	popd
}

configure-mjpg() {
	configure echo Done
}
compile-mjpg() {
	compile $MAKE CC="$GCC" \
		EXTRA_LDFLAGS="-L $STAGING_USR/lib" \
		EXTRA_CFLAGS="-Os -I$STAGING_USR/include $TARGET_CFLAGS" \
		STATIC=1
}
install-mjpg() {
	log_install echo Done
}
deploy-mjpg() {
	deploy cp -ra mjpg_streamer www "$ROOTFS"/bin/

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

