
PACKAGES+=" sensors"
hset sensors url "none"
hset sensors dir "."
hset sensors destdir "$STAGING_USR"
hset sensors depends "libusb"

configure-sensors() {
	configure echo Done
}
compile-sensors() {
	compile-generic \
		-C $HOME/Sources/Utils/sensors \
		CROSS_COMPILE="$TARGET_FULL_ARCH"- \
		EXTRA_LDFLAGS="$LDFLAGS_RLINK" \
		EXTRA_CFLAGS="$CFLAGS" 
}
install-sensors() {
	install-generic \
		-C $HOME/Sources/Utils/sensors \
		CROSS_COMPILE="$TARGET_FULL_ARCH"-
}
deploy-sensors() {
	deploy cp "$STAGING_USR"/bin/sensor* "$ROOTFS"/usr/bin/
	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	
	echo "* Starting sensor-mcast..."
	/usr/bin/sensors-mcast -d
	EOF
}


PACKAGES+=" fbvncslave"
hset fbvncslave url "none"
hset fbvncslave dir "."
hset fbvncslave destdir "$STAGING_USR"
hset fbvncslave depends "libvncserver"

configure-fbvncslave() {
	configure echo Done
}
compile-fbvncslave() {
	compile-generic \
		-C $HOME/Sources/Utils/fbvncslave \
		LDFLAGS="$LDFLAGS_RLINK"
}
install-fbvncslave() {
	install-generic \
		-C $HOME/Sources/Utils/fbvncslave
}
deploy-fbvncslave() {
	deploy cp "$STAGING_USR"/bin/fbvncslave "$ROOTFS"/usr/bin/
}

