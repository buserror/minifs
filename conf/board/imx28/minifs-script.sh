#!/bin/bash

. "$CONF_BASE"/arch/mxs.sh

# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/

TARGET_KERNEL_DTB=${TARGET_KERNEL_DTB:-imx28-evk}
TARGET_KERNEL_CMDLINE=${TARGET_KERNEL_CMDLINE:-"console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc quiet"}

board_set_versions() {
	mxs-set-versions
	TARGET_FS_SQUASH=0
	TARGET_FS_EXT2=1
	TARGET_SHARED=1 
}

board_prepare() {
	TARGET_PACKAGES+=" gdbserver strace"
	TARGET_PACKAGES+=" curl"
	TARGET_PACKAGES+=" openssh sshfs"

	TARGET_PACKAGES+=" targettools i2c"
	TARGET_PACKAGES+=" kexec-tools"
	
	TARGET_PACKAGES+=" linux-dtb elftosb"
	
	hset uboot url "git!git://git.denx.de/u-boot.git#uboot-imx28-git.tar.bz2"
	hset uboot target "u-boot.sb"
	hset uboot board "mx28evk"

	hset elftosb board "iMX28_EVK"

}

imx28-deploy-linux-dtb() {
	deploy-linux-dtb
	if [ -f $BUILD/kernel.ub ]; then
		cp $BUILD/kernel.ub $ROOTFS/linux
	fi
	if [ -f $BUILD/$TARGET_KERNEL_DTB.dtb ]; then
		cp $BUILD/$TARGET_KERNEL_DTB.dtb $ROOTFS/linux.dtb
	fi
}

imx28-compile-uboot() {
	compile-uboot &&
		tools/mxsboot sd u-boot.sb ../u-boot.sd
}

board_local() {
	# how to use kexec from the board to launch a new kernel
	tftp -g -r linux -l /tmp//linux 192.168.2.129 &&	kexec --append="$(cat /proc/cmdline)" --force /tmp/linux
	tftp -g -r linux -l /tmp/linux 192.168.2.129 &&	kexec --append="console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc" --force --no-ifdown /tmp/linux


	ext4load mmc 0:2 ${fdt_addr} linux.dtb
	ext4load mmc 0:2 ${loadaddr} linux
	setenv bootargs root=/dev/mmcblk0p2 ro rootwait console=ttyAMA0,115200 ssp1=mmc quiet
	bootm ${loadaddr} - ${fdt_addr}
	
}
