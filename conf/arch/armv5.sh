
TARGET_META_ARCH=armv5

TARGET_ARCH=arm
TARGET_FULL_ARCH=$TARGET_ARCH-v5-linux-uclibcgnueabi
TARGET_KERNEL_NAME=uImage
TARGET_LIBC_CFLAGS="-g -O2 -march=armv5te -mtune=arm926ej-s -fPIC -mthumb-interwork"
TARGET_CFLAGS="$TARGET_LIBC_CFLAGS"
