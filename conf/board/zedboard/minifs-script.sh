

TARGET_META_ARCH=armv7

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-a9-linux-gnueabi
TARGET_KERNEL_NAME=uImage
TARGET_LIBC_CFLAGS="-g -O2 -march=armv7-a -mtune=cortex-a9 -mfpu=neon -fPIC -mthumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"
TARGET_LIBC=eglibc

TARGET_KERNEL_NAME=uImage
# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/
TARGET_KERNEL_DTB=${TARGET_KERNEL_DTB:-zynq-zed}
TARGET_KERNEL_CMDLINE=${TARGET_KERNEL_CMDLINE:-"console=ttyAMA0,115200 root=/dev/mmcblk0p2 ro rootwait ssp1=mmc quiet"}

TARGET_FS_EXT=0
#TARGET_FS_TAR=0
TARGET_FS_SQUASH=1

board_set_versions() {
	TARGET_SHARED=1
	TARGET_INITRD=1
#	TARGET_X11=1
}

board_prepare() {
	hset linux version "3.10"
	hset linux url "git!https://github.com/Xilinx/linux-xlnx.git#linux-zynq.tar.bz2"
	hset linux make-extra-parameters "UIMAGE_LOADADDR=0x8000"

	TARGET_PACKAGES+=" uboot"
	hset uboot url "git!https://github.com/Xilinx/u-boot-xlnx.git#uboot-zynq-git.tar.bz2"
	hset uboot target "zynq_zed"
	hset uboot board "zynq_zed"

	TARGET_PACKAGES+=" xbootgen"

	TARGET_PACKAGES+=" gdbserver strace catchsegv"
	TARGET_PACKAGES+=" ethtool"
	TARGET_PACKAGES+=" curl rsync"
#	TARGET_PACKAGES+=" openssh sshfs mDNSResponder"

	TARGET_PACKAGES+=" i2c mtd_utils "
	hset mtd_utils deploy-list "nandwrite mtd_debug"

	TARGET_PACKAGES+=" targettools"

		# all of that for gtk
#	TARGET_PACKAGES+=" libjpeg libpng libfreetype libfontconfig libpixman"
#	TARGET_PACKAGES+=" xorgserver xorginputevdev"
#	TARGET_PACKAGES+=" xorgvideofbdev"
#	TARGET_PACKAGES+=" x11vnc xhost"
#	TARGET_PACKAGES+=" xorgfontutil xorgfontadobe"
#	TARGET_PACKAGES+=" msfonts libwebkit"

	TARGET_PACKAGES+=" libalsa"

	ROOTFS_KEEPERS+="libnss_compat.so.2:"
	ROOTFS_KEEPERS+="libnss_files.so.2:"
	export ROOTFS_KEEPERS

}

zedboard-configure-uboot() {
	if ! grep CONFIG_MACH_TYPE ./include/configs/zynq_zed.h >/dev/null; then
		echo "   Patching uboot git MACH_TYPE"
		sed -i -e '/PHYS_SDRAM_1_SIZE/i \
#define CONFIG_MACH_TYPE 0xd32\
'  			./include/configs/zynq_zed.h
	fi
	if grep msoft-float arch/arm/cpu/armv7/config.mk >/dev/null; then
		echo "   Patching uboot msoft-float issue"
		sed -i -e 's/-msoft-float/-mfloat-abi=hard -mfpu=vfpv3/g' \
			arch/arm/cpu/armv7/config.mk
	fi
	configure-generic
}

zedboard-deploy-sharedlibs() {
#	cp "$BUILD/kernel.ub" "$ROOTFS"/
	deploy-sharedlibs
	if [ ! -e "$ROOTFS"/lib/ld-linux.so.3 ]; then
		echo "     Fixing armhf loader"
		ln -sf ld-linux-armhf.so.3 "$ROOTFS"/lib/ld-linux.so.3
	fi
	mkdir -p "$ROOTFS"/root
}

zedboard-setup-initrd() {
	mkdir -p $BUILD/initramfs
	rm -rf $BUILD/initramfs/*
	ROOTFS_INITRD="../initramfs"
	echo  " Building $ROOTFS_INITRD"
	(
		cd $BUILD/busybox
		echo Reinstalling busybox there
		ROOTFS=$ROOTFS_INITRD
		deploy-busybox-local
	) >$BUILD/._initramfs.log
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

PACKAGES+=" xbootgen"
hset xbootgen url "git!https://github.com/buserror-uk/zynq-xbootgen.git#zynq-xbootgen.tar.bz2"
hset xbootgen depends "uboot"
hset xbootgen phases "deploy"

deploy-xbootgen-local() {
	(
		host-setup
		$MAKE O=$STAGING_TOOLS &&
		xbootgen zynq_zedboard_fsbl.elf ../uboot/u-boot
		if [ -f boot.bin ]; then
			mv boot.bin ../BOOT.BIN
		fi
	) || exit 1
}
deploy-xbootgen() {
	touch ._install_$PACKAGE
	deploy deploy-xbootgen-local
}

