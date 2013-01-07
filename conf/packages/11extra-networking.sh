
# iptables http://www.netfilter.org/projects/iptables/downloads.html
PACKAGES+=" iptables"
#hset iptables url "http://www.netfilter.org/projects/iptables/files/iptables-1.4.12.1.tar.bz2"
hset iptables url "http://ftp.de.debian.org/debian/pool/main/i/iptables/iptables_1.4.14.orig.tar.bz2"

configure-iptables() {
	configure-generic 
	#--disable-ipv6
}
deploy-iptables() {
	ROOTFS_PLUGINS+="$ROOTFS/lib/xtables:"
	deploy deploy_binaries
}

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
hset openssh url "http://mirror.bytemark.co.uk/OpenBSD/OpenSSH/portable/openssh-6.1p1.tar.gz"
hset openssh depends "openssl zlib"
hset openssh sysconf "/etc/ssh"

setup-openssh() {
	hset openssl deploy true
}
configure-openssh-local() {
	configure-generic-local LD="ccfix $TARGET_FULL_ARCH-gcc" \
		--sysconfdir=/etc/ssh \
		--libexecdir=/usr/lib/libexec
	sed -i \
		-e 's|#define HAVE_ADDR_V6_IN_UTMP 1|#undef HAVE_ADDR_V6_IN_UTMP|g' \
		-e 's|#define HAVE_ADDR_V6_IN_UTMPX 1|#undef HAVE_ADDR_V6_IN_UTMPX|g' \
		config.h
}
configure-openssh() {
	configure configure-openssh-local
}
deploy-openssh-local() {
	deploy_binaries
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
	mkdir -p $ROOTFS/etc/ssh/ $ROOTFS/var/empty/ && \
		cp $CONFIG/ssh_host_* $ROOTFS/etc/ssh/
}
deploy-openssh() {
	deploy deploy-openssh-local
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

#
# dns/dhcp server/forwarder
#
PACKAGES+=" dnsmasq"
hset dnsmasq url "http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.59.tar.gz"
hset dnsmasq optional "dbus"

configure-dnsmasq-local() {
	sed -i -e 's/\/usr\/local/\/usr/' Makefile
	sed -i \
		-e '/#undef HAVE_IPV6/d' \
		-e '/struct all_addr {/i\
#undef HAVE_IPV6
' src/dnsmasq.h
}
configure-dnsmasq() {
	configure  configure-dnsmasq-local
}
compile-dnsmasq() {
	compile-generic CC="ccfix $TARGET_FULL_ARCH-gcc" CFLAGS="$CFLAGS"
}
deploy-dnsmasq() {
	deploy deploy_binaries
}


PACKAGES+=" ethtool"
hset ethtool url "http://ftp.kernel.org/pub/software/network/ethtool/ethtool-3.1.tar.bz2"

deploy-ethtool() {
	deploy deploy_binaries
}

PACKAGES+=" fuse"
hset fuse url "http://downloads.sourceforge.net/project/fuse/fuse-2.X/2.9.2/fuse-2.9.2.tar.gz"

deploy-fuse() {
	deploy deploy_binaries
}

PACKAGES+=" sshfs"
hset sshfs url "http://downloads.sourceforge.net/project/fuse/sshfs-fuse/2.4/sshfs-fuse-2.4.tar.gz"
hset sshfs depends "fuse openssh libglib"

configure-sshfs() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic
	export LDFLAGS="$LDFLAGS_BASE"	
}

deploy-sshfs() {
	deploy deploy_binaries
}

PACKAGES+=" dma"
hset dma url "https://github.com/corecode/dma/archive/v0.8.tar.gz"
hset dma depends "openssl"

compile-dma() {
	compile-generic \
		CPPFLAGS="$TARGET_CFLAGS $TARGET_CPPFLAGS -DHAVE_GETPROGNAME -Dgetprogname\(\)='\"dma\"'" \
		PREFIX="/usr"
}

install-dma() {
	install-generic \
		PREFIX="/usr"
}

deploy-dma() {
	deploy deploy_binaries
}
