
#
# Internet routing daemon
#
PACKAGES+=" bird"
hset bird url "ftp://bird.network.cz/pub/bird/bird-1.2.2.tar.gz"
hset bird depends "libreadline"

#
# Secure Shell (bigger version than dropbear)
#
PACKAGES+=" openssh"
hset openssh url "ftp://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-5.6p1.tar.gz"
hset openssh depends "openssl"

#
# tinc tunelling - http://www.tinc-vpn.org/
#
PACKAGES+=" tinc"
hset tinc url "http://www.tinc-vpn.org/packages/tinc-1.0.14.tar.gz"
hset tinc depends "zlib lzo openssl"

deploy-tinc-local() {
	cp "$STAGING_USR"/sbin/tincd "$ROOTFS"/sbin/
	mkdir -p "$ROOTFS"/etc/tinc
	sed -i '
/^# LAUNCH APPS/ a\
if [ -f /etc/tinc/nets.boot ]; then\
	/sbin/tincd -n $(cat /etc/tinc/nets.boot)\
fi\
' "$ROOTFS"/etc/init.d/rcS
}

deploy-tinc() {
	deploy deploy-tinc-local
}

#
# IMAP/POP/*.*/SMTP library - http://sourceforge.net/projects/libetpan/
#
PACKAGES+=" libetpan"
hset libetpan url "http://downloads.sourceforge.net/project/libetpan/libetpan/1.0/libetpan-1.0.tar.gz"
hset libetpan depends "zlib"

# http://www.sourcefiles.org/System/Daemons/DNS/
PACKAGES+=" mdnsd"
hset mdnsd url "http://www.sourcefiles.org/System/Daemons/DNS/mdnsd-0.7G.tar.gz"
hset mdnsd destdir "$STAGING_USR"

deploy-mdnsd() {
	deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
}
