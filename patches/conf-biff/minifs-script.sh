
TARGET_ARCH=i486
TARGET_FULL_ARCH=$TARGET_ARCH-biff-linux-uclibc
TARGET_KERNEL_NAME=bzImage
TARGET_KERNEL_ARCH=x86
TARGET_CFLAGS="-Os -march=i486"
TARGET_INITRD=1

board_prepare()
{
	TARGET_PACKAGES+=" libjpeg mjpg libusb libftdi"
	if [ -d $HOME/Sources/Utils/sensors ]; then
		TARGET_PACKAGES+=" sensors"
	fi
}
