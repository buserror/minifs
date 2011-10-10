PACKAGES+=" alsadrivers"
hset alsadrivers url "ftp://ftp.alsa-project.org/pub/driver/alsa-driver-1.0.24.tar.bz2"
hset alsadrivers depends "linux-modules"

PACKAGES+=" libalsa"
hset libalsa url "ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.0.24.1.tar.bz2"
#hset libalsa depends "alsadrivers"

configure-libalsa() {
	configure-generic --disable-python
}

deploy-libalsa() {
	mkdir -p "$ROOTFS"/var/lib/alsa
	deploy rsync -a "$STAGING_USR"/share/alsa "$ROOTFS"/usr/share/
}

PACKAGES+=" alsaplugins"
hset alsaplugins url "ftp://ftp.alsa-project.org/pub/plugins/alsa-plugins-1.0.24.tar.bz2"
hset alsaplugins depends "libalsa"

PACKAGES+=" alsautils"
hset alsautils url "ftp://ftp.alsa-project.org/pub/utils/alsa-utils-1.0.24.2.tar.bz2"
hset alsautils depends "libalsa libncurses"

configure-alsautils() {
	configure-generic --disable-xmlto --with-curses=ncurses
}

deploy-alsautils() {
	deploy deploy_binaries
}
