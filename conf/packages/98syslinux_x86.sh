
PACKAGES+=" syslinux"
hset syslinux url "http://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-4.03.tar.bz2"
#hset syslinux depends "linux-modules"
hset syslinux phases "deploy"


deploy-syslinux() {
	deploy echo Done
}
