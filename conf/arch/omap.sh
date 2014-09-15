TARGET_META_ARCH=armv7
MINIFS_BOARD_ROLE+=" omap"

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-a8-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage
TARGET_LIBC_CFLAGS="-g -O2 -march=armv7-a -mtune=cortex-a8 -mfpu=neon -fPIC -mthumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"

ax0-prepare() {
	echo SET kernet version
	hset linux version "3.16"
	hset linux make-extra-parameters "UIMAGE_LOADADDR=0x40008000"

	TARGET_PACKAGES+=" uboot"
	hset uboot url "git!https://github.com/jwrdegoede/u-boot-sunxi.git#uboot-sunxi-git.tar.bz2"
	hset uboot board "A10-OLinuXino-Lime"
	hset uboot target "u-boot-sunxi-with-spl.bin"
}


omap-deploy-sharedlibs() {
	deploy-sharedlibs
	if [ ! -e "$ROOTFS"/lib/ld-linux.so.3 ]; then
		echo "     Fixing armhf loader"
		ln -sf ld-linux-armhf.so.3 "$ROOTFS"/lib/ld-linux.so.3
	fi
	mkdir -p "$ROOTFS"/root
}
