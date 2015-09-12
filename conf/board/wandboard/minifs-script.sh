
TARGET_LIBC=eglibc

TARGET_META_ARCH=armv7
TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-a9-linux-gnueabi
TARGET_KERNEL_NAME=uImage
TARGET_LIBC_CFLAGS="-g -O2 -march=armv7-a -mtune=cortex-a9 -mfpu=neon -fPIC -mthumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"

# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/
TARGET_KERNEL_DTB=${TARGET_KERNEL_DTB:-imx6q-wandboard}
TARGET_KERNEL_CMDLINE=${TARGET_KERNEL_CMDLINE:-"console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc quiet"}

TARGET_FS_EXT=0
#TARGET_FS_TAR=0
TARGET_FS_SQUASH=1

board_set_versions() {
	TARGET_SHARED=1
	TARGET_INITRD=1

	hset linux version "3.14"
	TARGET_KERNEL_NAME=zImage
}

board_prepare() {
	TARGET_PACKAGES+=" uboot"
	hset uboot url "git!http://git.denx.de/u-boot.git#uboot-imx6-git.tar.bz2"
	hset uboot target "u-boot.imx"
	hset uboot board "wandboard_quad"

	TARGET_PACKAGES+=" firmware-wandboard"
	TARGET_PACKAGES+=" linux-firmware"

	TARGET_PACKAGES+=" gdbserver strace catchsegv"
	TARGET_PACKAGES+=" ethtool"
	TARGET_PACKAGES+=" curl rsync"
	TARGET_PACKAGES+=" openssh sshfs" # mDNSResponder

	TARGET_PACKAGES+=" i2c"

	TARGET_PACKAGES+=" targettools"

		# Audio stuff
	TARGET_PACKAGES+=" libalsa aften lame twolame alsautils"
	TARGET_PACKAGES+=" ffmpeg shairport-sync mpd"
	hset shairport name "Loungeaudio"
	hset gmrender name "Loungeaudio"
	
	ROOTFS_KEEPERS+="libnss_compat.so.2:"
	ROOTFS_KEEPERS+="libnss_files.so.2:"
	export ROOTFS_KEEPERS

}

#
# Create a ramdisk image with just busybox and a few tools, this
# mini ramdisk is responsible for finding were the real linux distro is
# mount it and start it
#
wandboard-setup-initrd() {
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


PACKAGES+=" firmware-wandboard"
hset firmware-wandboard depends "linux-firmware"
hset firmware-wandboard dir "linux-firmware"
hset firmware-wandboard url "none"
hset firmware-wandboard phases "deploy"

deploy-firmware-wandboard-local() {
	mkdir -p "$ROOTFS"/lib/firmware/brcm
	cp brcm/brcmfmac4329-sdio.bin "$ROOTFS"/lib/firmware/brcm/
	cp "$CONFIG"/brcmfmac-sdio.txt "$ROOTFS"/lib/firmware/brcm/brcmfmac-sdio.txt
	cp "$CONFIG"/brcmfmac-sdio.txt "$ROOTFS"/lib/firmware/brcm/brcmfmac4329-sdio.txt
}
deploy-firmware-wandboard() {
	if [ ! -f "._install_$PACKAGE" ]; then
		touch "._install_$PACKAGE"
	fi
	deploy deploy-firmware-wandboard-local
}
