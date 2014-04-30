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

PACKAGES+=" lame"
hset lame url "http://skylink.dl.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz"

deploy-lame() {
	deploy deploy_binaries
}

PACKAGES+=" twolame"
hset twolame url "http://cznic.dl.sourceforge.net/project/twolame/twolame/0.3.13/twolame-0.3.13.tar.gz"

deploy-twolame() {
	deploy deploy_binaries
}

PACKAGES+=" aften"
hset aften url "git!https://github.com/buserror-uk/aften.git#aften-git.tar.bz2"
hset aften destdir "$STAGING_USR"

deploy-aften() {
	deploy deploy_binaries
}

PACKAGES+=" shairport"
hset shairport url "git!https://github.com/abrasive/shairport.git#shairport-git.tar.bz2"
hset shairport depends "libalsa openssl avahi"

configure-shairport() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic 
	export LDFLAGS="$LDFLAGS_BASE"
}

install-shairport() {
	install-generic PREFIX=/usr
}

deploy-shairport-local() {
	deploy_binaries
	
	cat >>"$ROOTFS"/etc/network-up.sh <<-EOF
	echo "* Starting shairport..."
	shairport -d -a \$(hostname)
	EOF
}
deploy-shairport() {
	deploy deploy-shairport-local
}
 
PACKAGES+=" libupnp"
hset libupnp url "http://downloads.sourceforge.net/project/pupnp/pupnp/libUPnP%201.6.19/libupnp-1.6.19.tar.bz2"

PACKAGES+=" gmrender"
hset gmrender url "git!https://github.com/hzeller/gmrender-resurrect.git#gmrender-git.tar.bz2"
hset gmrender depends " libupnp gst-plugins-good gst-plugins-bad gst-plugins-ugly"

configure-gmrender() {
	configure-generic LDFLAGS="$LDFLAGS_RLINK"
}
