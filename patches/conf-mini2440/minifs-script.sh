#!/bin/bash

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-minifs-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage
TARGET_CFLAGS="-Os -march=armv4t -mtune=arm920t -mthumb-interwork -mthumb "

function board_prepare() {
	VERSION_linux=2.6.32.7
	true
}

board_finish() {
	echo "board_finish"
}

board_compile() {
	echo "board_compile"
}
