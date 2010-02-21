#!/bin/bash

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-minifs-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage
TARGET_CFLAGS="-Os -march=armv4t -mtune=arm920t -mthumb-interwork -mthumb "

function board_prepare() {
	VERSION_linux=2.6.32.7

#url[${#url[@]}]="http://www.opensource.apple.com/darwinsource/tarballs/other/mDNSResponder-107.6.tar.gz"

	# for a >64Mb nand with 2k blocks and 128k erase blocks
	TARGET_FS_JFFS2="-q -l -p -e 0x20000 -s 0x800"
}

board_finish() {
	echo "board_finish"
}

board_compile() {
	echo "board_compile"
}
