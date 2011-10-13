
#
# Internet routing daemon
#
PACKAGES+=" bird"
hset bird url "ftp://bird.network.cz/pub/bird/bird-1.2.2.tar.gz"
hset bird depends "libreadline busybox"

#
# Secure Shell (bigger version than dropbear)
#
PACKAGES+=" openssh"
hset openssh url "ftp://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-5.9p1.tar.gz"
hset openssh depends "openssl"
hset openssh sysconf "/etc/ssh"

setup-openssh() {
	hset openssl deploy 1
}
configure-openssh() {
	configure-generic LD="ccfix $TARGET_FULL_ARCH-gcc" \
		--sysconfdir=/etc/ssh \
		--libexecdir=/usr/lib/libexec
}
deploy-openssh() {
	deploy deploy_binaries
	cat >>"$ROOTFS"/etc/passwd <<-END
	sshd:x:1001:1001:sshd:/home:/bin/false
	END
	cat >>"$ROOTFS"/etc/group <<-END
	sshd:x:1001:
	END
	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	echo "* Starting sshd..."
	/usr/sbin/sshd
	EOF
	if [ ! -f $CONFIG/ssh_host_rsa_key ]; then
		echo "  ## Generating new host keys for OpenSSH"
		ssh-keygen -P "" -t rsa -f  $CONFIG/ssh_host_rsa_key
		ssh-keygen -P "" -t dsa -f  $CONFIG/ssh_host_dsa_key
	fi
	mkdir -p "$ROOTFS"/var/log &&
		touch "$ROOTFS"/var/log/lastlog
	mkdir -p $ROOTFS/etc/ssh/ $ROOTFS/var/empty/ && cp $CONFIG/ssh_host_* $ROOTFS/etc/ssh/
}

#
# tinc tunelling - http://www.tinc-vpn.org/
#
PACKAGES+=" tinc"
hset tinc url "http://www.tinc-vpn.org/packages/tinc-1.0.14.tar.gz"
hset tinc depends "zlib lzo openssl busybox"

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
hset libetpan configscript "libetpan-config"

# http://www.sourcefiles.org/System/Daemons/DNS/
PACKAGES+=" mdnsd"
hset mdnsd url "http://www.sourcefiles.org/System/Daemons/DNS/mdnsd-0.7G.tar.gz"
hset mdnsd destdir "$STAGING_USR"
hset mdnsd depends "busybox"

deploy-mdnsd() {
	deploy deploy_binaries
}
