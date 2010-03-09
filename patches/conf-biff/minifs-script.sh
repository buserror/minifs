
TARGET_ARCH=i486
TARGET_FULL_ARCH=$TARGET_ARCH-biff-linux-uclibc
TARGET_KERNEL_NAME=bzImage
TARGET_KERNEL_ARCH=x86
TARGET_CFLAGS="-Os -march=i486"

board_prepare()
{
	TARGET_PACKAGES+=" libjpeg mjpg libusb libftdi"
}
