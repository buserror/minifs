
#
# tinc tunelling
#
PACKAGES+=" tinc"
hset url tinc "http://www.tinc-vpn.org/packages/tinc-1.0.13.tar.gz"
hset depends tinc "zlib lzo openssl"

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
# Internet routing daemon
#
PACKAGES+=" bird"
hset url bird "ftp://bird.network.cz/pub/bird/bird-1.2.2.tar.gz"

#
# Secure Shell (bigger version than dropbear)
#
PACKAGES+=" openssh"
hset url openssh "ftp://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-5.5p1.tar.gz"
hset depends openssh "openssl"
