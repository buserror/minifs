#!/bin/bash

TARGET_ARCH=i386
TARGET_FULL_ARCH=$TARGET_ARCH-minifs-linux-uclibc
TARGET_KERNEL_NAME=bzImage
TARGET_CFLAGS="-Os"

board_prepare()
{
	TARGET_PACKAGES+=" libjpeg mjpg zlib dropbear"
}
