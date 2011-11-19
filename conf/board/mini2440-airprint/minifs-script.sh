#!/bin/bash

. "$CONF_BASE"/arch/armv4.sh

MINIFS_BOARD_UBOOT=mini2440

board_set_versions() {
	hset linux version "3.0.4"
	# for a >64Mb nand with 2k blocks and 128k erase blocks
#	TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"
	TARGET_INITRD=0
	TARGET_SHARED=1 
	hset uboot url "git!git://repo.or.cz/u-boot-openmoko/mini2440.git#uboot-mini2440-git.tar.bz2"
}

board_prepare() {
	TARGET_PACKAGES+=" uboot strace gdb "
	TARGET_PACKAGES+=" tinc openssh rsync iptables dnsmasq"
	TARGET_PACKAGES+=" cups cups-splix ghostscript msfonts"
	
	{
		if [ ! -d "$CONFIG"/rootfs/etc/tinc/ ]; then
			mkdir -p "$CONFIG"/rootfs/etc/tinc/ &&
			rsync -a root@yuck:/etc/tinc/client-williamses/ "$CONFIG"/rootfs/etc/tinc/
		fi
	} || echo No tinc config found, ignoring
}

mini2440-airprint-deploy-filesystem-prepack() {
	deploy-filesystem-prepack
	echo airprint >"$ROOTFS"/etc/hostname
	sed -i \
		-e 's|noatime |noatime,commit=900 |' \
		-e '
/devtmpfs/d
/^# LOAD MODULES/ a\
echo 3 >/proc/cpu/alignment\
crond
' "$ROOTFS"/etc/init.d/rcS

	mkdir -p "$ROOTFS"/var/spool/cron/crontabs
	echo "5 5 * * * rdate -s ntp >/dev/null 2>&1" >"$ROOTFS"/var/spool/cron/crontabs/root
	echo $(dig ntp|awk '/^ntp\./ { print $5 }') ntp >>"$ROOTFS"/etc/hosts
	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	rdate -s ntp &
	EOF
}

mini2440-airprint-deploy-uboot() {
	# make sure the u-boot is aligned on 2k blocks, for mtd_debug
	dd if=u-boot.bin of="$BUILD"/u-boot.bin bs=2048 conv=sync >/dev/null 2>&1
	optional deploy-uboot
	# update this config file so fw_print/setenv works on the board
	echo "/dev/mtd1 0x0 0x20000 0x20000" >"$ROOTFS"/etc/fw_env.config
	# mmcinit;ext2load mmc 0:2 32000000 /linux;bootm
}

mini2440-airprint-deploy-openssh() {
	optional deploy-openssh
	# remove telnetd, since we have ssh working
	sed -i -e '/telnetd/d' "$ROOTFS"/etc/init.d/rcS
}

mini2440-airprint-deploy-linux-bare() {
	deploy-linux-bare
	cp "$BUILD"/kernel.ub "$ROOTFS"/linux
}

mini2440-airprint-deploy-cups() {
	deploy-cups
	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	echo "* Starting cupsd..."
	cupsd &
	EOF
}

mini2440-airprint-deploy-mDNSResponder() {
	deploy-mDNSResponder
	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	echo "* Starting mdnsd..."
	mdnsd &
	EOF
	sed -i -e "s|syslog.*$|syslogd -D|" "$ROOTFS"/etc/init.d/rcS
}
