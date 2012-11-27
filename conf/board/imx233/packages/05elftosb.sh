
PACKAGES+=" elftosb"
hset elftosb url "git!git://github.com/buserror-uk/Olinuxino-Micro-Bootlets.git#Olinuxino-Bootlets.tar.bz2"
hset elftosb depends "linux-dtb"
hset elftosb phases "deploy"

deploy-elftosb-local() {
	ln -sf $(hget linux-dtb filename) zImage
	rm -f mv sd_mmc_bootstream.raw
	echo $TARGET_KERNEL_CMDLINE >linux_prep/cmdlines/stmp378x_dev.txt
	echo $TARGET_KERNEL_CMDLINE >>linux_prep/cmdlines/stmp378x_dev.txt
	$MAKE \
		CROSS_COMPILE="${CROSS}-" && \
		mv sd_mmc_bootstream.raw ..
}

deploy-elftosb() {
	# make sure we deploy after linux-dtb
	if [ -f "$BUILD"/linux/._deploy_linux-dtb ]; then
		touch ._install_$PACKAGE
	fi
	deploy deploy-elftosb-local
}
