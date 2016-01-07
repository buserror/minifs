#!/bin/bash

. "$CONF_BASE"/arch/armv4.sh

#TARGET_CFLAGS="-Os -mcpu=arm926ej-s -mtune=arm920t "

TARGET_KERNEL_NAME=zImage
TARGET_INITRD=1
# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/
#TARGET_KERNEL_DTB=${TARGET_KERNEL_DTB:-imx23-olinuxino}
#TARGET_KERNEL_CMDLINE=${TARGET_KERNEL_CMDLINE:-"console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc quiet"}

board_set_versions() {
	hset linux version "4.1"
	hset linux url "git!https://github.com/ARMWorks/linux-4.x.y.git#linux-nanopi.tar.bz2"
	hset linux git-ref "master"
	TARGET_FS_SQUASH=1
	TARGET_FS_EXT2=1
	TARGET_SHARED=1
}

board_prepare() {
	TARGET_PACKAGES+=" gdbserver strace"
	TARGET_PACKAGES+=" curl wpa-supplicant wireless-tools hostapd"
#	TARGET_PACKAGES+=" firmware-rtl firmware-ralink"
	TARGET_PACKAGES+=" openssh sshfs"

	TARGET_PACKAGES+=" targettools"
	TARGET_PACKAGES+=" kexec-tools"

#	TARGET_PACKAGES+=" libsdl sdlvoxel sdlplasma libpng libsdlimage kobodeluxe mplayer"
#	TARGET_PACKAGES+=" font-bitstream-vera rrdtool"
	TARGET_PACKAGES+=" nanoboot"
}

nanopi-deploy-sharedlibs() {
	deploy-sharedlibs
	mkdir -p "$ROOTFS"/rw
}


PACKAGES+=" nanoboot"
hset nanoboot url "git!https://github.com/ARMWorks/NanoPi-nanoboot.git#nanoboot.tar.bz2"
hset nanoboot depends "busybox"

configure-nanoboot() {
	configure echo Done
}
compile-nanoboot() {
	compile-generic CROSS_COMPILE="$TARGET_FULL_ARCH-"
}

#
# Create a ramdisk image with just busybox and a few tools, this
# mini ramdisk is responsible for finding were the real linux distro is
# mount it and start it
#
nanopi-setup-initrd() {
	mkdir -p $BUILD/initramfs
	rm -rf $BUILD/initramfs/*
	ROOTFS_INITRD="../initramfs"
	echo  " Building trampoline $ROOTFS_INITRD"
	(
		(
			cd $BUILD/busybox
			echo Reinstalling busybox there
			ROOTFS=$ROOTFS_INITRD
			deploy-busybox-local
		)
		mkdir -p $STAGING/static/bin
		make -C $CONF_BASE/target-tools \
			STAGING=$STAGING/static MY_CFLAGS="-static -Os -std=gnu99"\
			TOOLS="waitfor_uevent fat_find" && \
			sstrip $STAGING/static/bin/* && \
			cp $STAGING/static/bin/* \
				$ROOTFS_INITRD/bin/
	)>$BUILD/._initramfs.log
	(
		cd $BUILD/initramfs/
		## Add rootfs overrides for boards
		for pd in $(minifs_locate_config_path initramfs 1); do
			if [ -d "$pd" ]; then
				echo "### Installing initramfs $pd"
				rsync -av --exclude=._\* "$pd/" "./"
			fi
		done
	) >>$BUILD/._initramfs.log
}
