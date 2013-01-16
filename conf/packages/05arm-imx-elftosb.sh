#
# imx23/imx28 bootlet generator
#
PACKAGES+=" elftosb"
hset elftosb url "git!git://github.com/buserror-uk/Olinuxino-Micro-Bootlets.git#Olinuxino-Bootlets.tar.bz2"
hset elftosb depends "linux-dtb"
hset elftosb phases "deploy"
hset elftosb board "stmp378x_dev"

deploy-elftosb-local() {
	ln -sf $(hget linux-dtb filename) zImage
	rm -f mv sd_mmc_bootstream.raw
	echo $TARGET_KERNEL_CMDLINE >linux_prep/cmdlines/$(hget elftosb board).txt
#	echo $TARGET_KERNEL_CMDLINE >>linux_prep/cmdlines/$(hget elftosb board).txt
	$MAKE \
		CROSS_COMPILE="${CROSS}-" \
		BOARD=$(hget elftosb board) && \
		mv sd_mmc_bootstream.raw .. && \
		cp elftosb-*/bld/linux/elftosb ../staging-tools/bin/
}

deploy-elftosb() {
	# make sure we deploy after linux-dtb
	if [ -f "$BUILD"/linux/._deploy_linux-dtb ]; then
		touch ._install_$PACKAGE
	fi
	deploy deploy-elftosb-local
}
