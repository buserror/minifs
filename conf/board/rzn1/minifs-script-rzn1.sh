
TARGET_META_ARCH=armv7
MINIFS_BOARD_ROLE+=" rzn1"

TARGET_ARCH=arm
TARGET_KERNEL_NAME=zImage
TARGET_LIBC_CFLAGS="-g -Os -march=armv7-a -mtune=cortex-a7 -mfloat-abi=hard -mfpu=vfpv4-d16 -fPIC -mno-thumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"

# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/
TARGET_KERNEL_DTB=rzn1d400-db
TARGET_KERNEL_CMDLINE=${TARGET_KERNEL_CMDLINE:-"debug console=ttyS0,115200 rdinit=/etc/init.sh"}

TARGET_FS_EXT=0
TARGET_FS_SQUASH=1

board_set_versions() {
	TARGET_SHARED=1
	TARGET_INITRD=1
	rzn1-prepare
}

board_prepare() {
	rzn1-prepare

	TARGET_PACKAGES+=" gdbserver strace catchsegv"

#	TARGET_PACKAGES+=" lrzsz"
	TARGET_PACKAGES+=" ethtool"
	TARGET_PACKAGES+=" targettools"
	TARGET_PACKAGES+=" mtd_utils"
	hset mtd_utils deploy-list "nandwrite mtd_debug mkfs.jffs2"
}

rzn1-prepare() {
	echo SET kernel version
	hset linux version "4.9"
	# Only for uImage
	#hset linux make-extra-parameters "UIMAGE_LOADADDR=0x80008000"

	TARGET_PACKAGES+=" uboot"
	hset uboot url "ftp://ftp.denx.de/pub/u-boot/u-boot-2017.01.tar.bz2"
	hset uboot board "$TARGET_KERNEL_DTB"
	hset uboot target "u-boot.bin"
}


board_finish()
{
	pushd $BUILD
	cp device-tree.dtb vmlinuz_padded
	dd if=vmlinuz-full.bin of=vmlinuz_padded conv=notrunc bs=1K seek=128
	truncate -s %64K vmlinuz_padded
	cp vmlinuz_padded minifs-full-squashfs.img /srv/tftp/
	ls -l /srv/tftp/vmlinuz_padded
	popd
}

#
# Create a ramdisk image with just busybox and a few tools, this
# mini ramdisk is responsible for finding were the real linux distro is
# mount it and start it. Note that you need something like a /etc/init.sh
# and the corresponding kernel parameter rdinit=/etc/init.sh for it to
# start.
# The configuration for the static busybox is config_busybox_mini.conf,
# You need to edit that to trim it down or use one from another board if
# applicable
#
rzn1-setup-initrd() {
	mkdir -p $BUILD/initramfs
	rm -rf $BUILD/initramfs/*
	ROOTFS_INITRD="$BUILD/initramfs"
	echo  " Building trampoline $ROOTFS_INITRD"
	(
		local bobj=$STAGING/obj/busybox-mini-obj
		if [ ! -d $bobj -o ! -f $bobj/.config ]; then
			mkdir -p $bobj
			if [ ! -f $CONFIG/config_busybox_mini.conf ]; then
				echo "WARNING using full busybox config"
				echo "   You need to edit config_busybox_mini.conf"
				cp $CONFIG/config_busybox.conf $CONFIG/config_busybox_mini.conf
			fi
			cp $CONFIG/config_busybox_mini.conf $bobj/.config
		fi
		(
			cd $BUILD/busybox
			echo Reinstalling busybox there
			for phase in oldconfig all install; do
				$MAKE O=$bobj CROSS_COMPILE="${CROSS}-" \
					CFLAGS="$TARGET_CFLAGS -Os" \
					CONFIG_PREFIX="$ROOTFS_INITRD" $MAKE_ARGUMENTS \
					$phase
			done
		) 2>&1
		# hset initrd tools "waitfor_uevent fat_find"
		if [ "$(hget initrd tools)" != "" ]; then
			mkdir -p $STAGING/static/bin
			make -C $CONF_BASE/target-tools \
				STAGING=$STAGING/static MY_CFLAGS="-static -Os -std=gnu99"\
				TOOLS="waitfor_uevent fat_find" && \
				sstrip $STAGING/static/bin/* && \
				cp $STAGING/static/bin/* \
					$ROOTFS_INITRD/bin/
		fi
	)>$BUILD/._initramfs.log
	(
		cd $ROOTFS_INITRD
		## Add rootfs overrides for boards
		for pd in $(minifs_locate_config_path initramfs 1); do
			if [ -d "$pd" ]; then
				echo "### Installing initramfs $pd"
				rsync -av --exclude=._\* "$pd/" "./"
			fi
		done
	) >>$BUILD/._initramfs.log
}
