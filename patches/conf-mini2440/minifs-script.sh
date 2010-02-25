#!/bin/bash

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-minifs-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage
TARGET_CFLAGS="-Os -march=armv4t -mtune=arm920t -mthumb-interwork -mthumb "

board_set_versions() {
	VERSION_linux=2.6.32.7
	# for a >64Mb nand with 2k blocks and 128k erase blocks
	TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"
}

board_prepare() {
	TARGET_PACKAGES+="zlib lzo e2fsprogs mtd_utils"
}

