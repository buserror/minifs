
. "$CONF_BASE"/arch/zynq.sh

TARGET_LIBC=eglibc

# this file .dts must exist either in this directory (board)
# or in the linux arch/$TARGET_ARCH/boot/dts/
TARGET_KERNEL_DTB=${TARGET_KERNEL_DTB:-zynq-zed}

TARGET_FS_EXT=0
#TARGET_FS_TAR=0
TARGET_FS_SQUASH=1

board_set_versions() {
	TARGET_SHARED=1
	TARGET_INITRD=1
#	TARGET_X11=1
}

board_prepare() {

	TARGET_PACKAGES+=" gdbserver strace catchsegv"
	TARGET_PACKAGES+=" ethtool"
	TARGET_PACKAGES+=" curl rsync"
#	TARGET_PACKAGES+=" openssh sshfs mDNSResponder"

	TARGET_PACKAGES+=" i2c mtd_utils "
	hset mtd_utils deploy-list "nandwrite mtd_debug"

	TARGET_PACKAGES+=" targettools"

	TARGET_PACKAGES+=" libalsa"

	ROOTFS_KEEPERS+="libnss_compat.so.2:"
	ROOTFS_KEEPERS+="libnss_files.so.2:"
	export ROOTFS_KEEPERS

}
