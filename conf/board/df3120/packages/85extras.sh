
PACKAGES+=" fbvncslave"
hset fbvncslave url "none"
hset fbvncslave dir "."
hset fbvncslave depends "libvncserver"

configure-fbvncslave() {
	configure echo Done
}
compile-fbvncslave() {
	compile echo Done
}
install-fbvncslave() {
	log_install $GCC $CPPFLAGS $CFLAGS -std=gnu99  \
		-Wall \
		"$CONFIG"/fbvncslave.c \
		-o "$STAGING_USR"/bin/fbvncslave $LDFLAGS_RLINK \
		-lvncclient -ljpeg -lz
}
deploy-fbvncslave() {
	deploy cp "$STAGING_USR"/bin/fbvncslave "$ROOTFS"/usr/bin/
}

