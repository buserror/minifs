
PACKAGES+=" libalsa"
hset libalsa url "ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.8.tar.bz2"

configure-libalsa-local() {
	rm -f config.sub; automake --add-missing
	configure-generic-local --disable-python
}
configure-libalsa() {
	configure configure-libalsa-local
}

deploy-libalsa-local() {
	mkdir -p "$ROOTFS"/var/lib/alsa
	ln -sf sh /etc/ash
	rsync -a "$STAGING_USR"/share/alsa "$ROOTFS"/usr/share/
}
deploy-libalsa() {
	deploy deploy-libalsa-local
}

PACKAGES+=" alsaplugins"
hset alsaplugins url "ftp://ftp.alsa-project.org/pub/plugins/alsa-plugins-1.1.8.tar.bz2"
hset alsaplugins depends "libalsa"

PACKAGES+=" alsautils"
hset alsautils url "ftp://ftp.alsa-project.org/pub/utils/alsa-utils-1.1.8.tar.bz2"
hset alsautils depends "libalsa libncurses"

configure-alsautils-local() {
	rm -f config.sub; automake --add-missing
	configure-generic-local --disable-xmlto --with-curses=ncurses
}
configure-alsautils() {
	configure configure-alsautils-local
}
deploy-alsautils() {
	deploy deploy_binaries
}

PACKAGES+=" lame"
hset lame url "http://skylink.dl.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz"

deploy-lame() {
	deploy deploy_binaries
}

configure-lame-local() {
	rm -f config.sub; automake --add-missing
	configure-generic-local
}

configure-lame() {
	configure configure-lame-local
}

PACKAGES+=" twolame"
hset twolame url "https://vorboss.dl.sourceforge.net/project/twolame/twolame/0.3.13/twolame-0.3.13.tar.gz"

deploy-twolame() {
	deploy deploy_binaries
}

PACKAGES+=" libmpg123"
hset libmpg123 url "http://netcologne.dl.sourceforge.net/project/mpg123/mpg123/1.19.0/mpg123-1.19.0.tar.bz2"

deploy-libmpg123() {
	deploy deploy_binaries
}



PACKAGES+=" aften"
hset aften url "git!https://github.com/buserror/aften.git#aften-git.tar.bz2"
hset aften destdir "$STAGING_USR"

deploy-aften() {
	deploy deploy_binaries
}

PACKAGES+=" shairport"
hset shairport url "git!https://github.com/abrasive/shairport.git#shairport-git.tar.bz2"
hset shairport depends "libalsa openssl avahi"
hset shairport name "\$(hostname)"

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
	shairport -d -a $(hget shairport name)
	EOF
}
deploy-shairport() {
	deploy deploy-shairport-local
}

PACKAGES+=" shairport-sync"
hset shairport-sync url "git!https://github.com/mikebrady/shairport-sync.git#shairport-sync-git.tar.bz2"
hset shairport-sync git-ref "2.8.6"
hset shairport-sync depends "libalsa libconfig libpopt openssl avahi"
hset shairport-sync name "\$(hostname)"

configure-shairport-sync-local() {
	# remove the non working autoscrap out of the way
	# replace with a 20 lines makefile that works
	rm -f configure* config.*
	cp $CONF_BASE/patches/shairport-sync/Makefile .
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic-local
	export LDFLAGS="$LDFLAGS_BASE"
}
configure-shairport-sync() {
	configure configure-shairport-sync-local
}

install-shairport-sync() {
	install-generic PREFIX=/usr
}

deploy-shairport-sync-local() {
	deploy_binaries

	cat >>"$ROOTFS"/etc/network-up.sh <<-EOF
	echo "* Starting shairport..."
	shairport -d -a $(hget shairport name)
	EOF
}
deploy-shairport-sync() {
	deploy deploy-shairport-sync-local
}

PACKAGES+=" libupnp"
hset libupnp url "http://downloads.sourceforge.net/project/pupnp/pupnp/libUPnP%201.6.19/libupnp-1.6.19.tar.bz2"

PACKAGES+=" gmrender"
hset gmrender url "git!https://github.com/hzeller/gmrender-resurrect.git#gmrender-git.tar.bz2"
hset gmrender depends " libupnp gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly"
hset gmrender name "\$(hostname)"

configure-gmrender() {
	configure-generic LDFLAGS="$LDFLAGS_RLINK"
}

deploy-gmrender-local() {
	deploy_binaries
	rsync -av --delete "$STAGING_USR"/share/gmediarender "$ROOTFS"/usr/share/
	cat >>"$ROOTFS"/etc/network-up.sh <<-EOF
	echo "* Starting gmrender..."
	gmediarender -d --logfile=/tmp/gmrender-run.log -f $(hget gmrender name) --gstout-audiosink=alsasink --gstout-audiodevice=default --gstout-initial-volume-db=-10>/tmp/gmrender.log 2>&1
	EOF
}

deploy-gmrender() {
	deploy 	deploy-gmrender-local
}

PACKAGES+=" faad"
hset faad url "http://downloads.sourceforge.net/faac/faad2-2.7.tar.bz2"

PACKAGES+=" libid3tag"
hset libid3tag url "http://http.debian.net/debian/pool/main/libi/libid3tag/libid3tag_0.15.1b.orig.tar.gz"

PACKAGES+=" libmpdclient"
hset libmpdclient url "http://www.musicpd.org/download/libmpdclient/2/libmpdclient-2.9.tar.xz"

configure-libmpdclient() {
	configure-generic --disable-documentation
}

PACKAGES+=" libsamplerate"
hset libsamplerate url "http://www.mega-nerd.com/SRC/libsamplerate-0.1.8.tar.gz"

# this piece of boatware doesn't build... we just need the headers anyway
PACKAGES+=" libboost"
hset libboost url "http://downloads.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.bz2"
hset libboost optional "libicu "

configure-libboost() {
#		echo "using gcc : arm : $TARGET_FULL_ARCH-g++ ;" >user-config.jam
		configure echo Done #./bootstrap.sh
}

compile-libboost() {
		compile echo Done # ./b2 toolset=gcc-arm target-os=linux
}
install-libboost() {
	log_install echo Lets not polute the staging with all that crap
}

PACKAGES+=" mpd"
hset mpd url "http://www.musicpd.org/download/mpd/0.19/mpd-0.19.10.tar.xz"
hset mpd depends "libboost libglib libexpat libalsa libcurl libsamplerate libid3tag libmpdclient libicu twolame libmpg123 faad"
hset mpd optional "avahi "

# there is a trick here, mpd /requires/ boost, but I don't want to build
# it, and since it only uses the header, I skip the test, Add JUST the
# header to the incluse list... that seems to work fine
configure-mpd() {
	configure-generic \
		LDFLAGS="$LDFLAGS_RLINK" \
		CPPFLAGS="$TARGET_CPPFLAGS -I$BUILD/libboost" --without-boost
}

deploy-mpd-local() {
	deploy_binaries

	cat >>"$ROOTFS"/etc/network-up.sh <<-EOF
	echo "* Starting mpd..."
	EOF
}
deploy-mpd() {
	deploy deploy-mpd-local
}
