
TARGET_META_ARCH=armv7
MINIFS_BOARD_ROLE+=" zynq"

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-a9-linux-gnueabi
TARGET_KERNEL_NAME=uImage
TARGET_LIBC_CFLAGS="-g -O2 -march=armv7-a -mtune=cortex-a9 -mfpu=neon -fPIC -mthumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"

zynq-prepare() {
	hset linux version "3.10"
	hset linux url "git!https://github.com/Xilinx/linux-xlnx.git#linux-zynq.tar.bz2"
	hset linux make-extra-parameters "UIMAGE_LOADADDR=0x8000"

	TARGET_PACKAGES+=" uboot"
	hset uboot url "git!https://github.com/Xilinx/u-boot-xlnx.git#uboot-zynq-git.tar.bz2"
	hset uboot target "zynq_zed"
	hset uboot board "zynq_zed"

	TARGET_PACKAGES+=" xbootgen"
}


zynq-configure-uboot() {
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

zynq-deploy-sharedlibs() {
#	cp "$BUILD/kernel.ub" "$ROOTFS"/
	deploy-sharedlibs
	if [ ! -e "$ROOTFS"/lib/ld-linux.so.3 ]; then
		echo "     Fixing armhf loader"
		ln -sf ld-linux-armhf.so.3 "$ROOTFS"/lib/ld-linux.so.3
	fi
	mkdir -p "$ROOTFS"/root
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

