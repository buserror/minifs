#!/bin/bash

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-v4t-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage
TARGET_LIBC_CFLAGS="-g -Os -march=armv4t -mtune=arm920t -mthumb-interwork -mthumb -fPIC"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS -fPIC"
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
	TARGET_PACKAGES+=" uboot gdbserver strace"
	TARGET_PACKAGES+=" tinc openssh"
	TARGET_PACKAGES+=" cups cups-splix ghostscript msfonts"
}

mini2440-airprint-deploy-filesystem-prepack() {
	deploy-filesystem-prepack
	echo AirPrint >"$ROOTFS"/etc/hostname
	sed -i \
		-e 's|noatime |noatime,commit=900 |' \
		-e '
/devtmpfs/d
/^# LOAD MODULES/ a\
echo 3 >/proc/cpu/alignment
' "$ROOTFS"/etc/init.d/rcS
}

mini2440-airprint-deploy-uboot() {
	# make sure the u-boot is aligned on 2k blocks, for mtd_debug
	deploy dd if=u-boot.bin of="$BUILD"/u-boot.bin bs=2048 conv=sync
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
