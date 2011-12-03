
# ftp://download.nvidia.com/XFree86/
NVIDIA_VERSION=290.10
NVIDIA_NAME="NVIDIA-Linux-$TARGET_ARCH-${NVIDIA_VERSION}"
PACKAGES+=" nvidia"
hset nvidia url "ftp://download.nvidia.com/XFree86/Linux-$TARGET_ARCH/$NVIDIA_VERSION/$NVIDIA_NAME.run"
hset nvidia depends "xorgserver linux-modules"

setup-nvidia() {
	ROOTFS_KEEPERS+="libvdpau.so:"
	ROOTFS_KEEPERS+="libvcuvid.so:"
	ROOTFS_KEEPERS+="libnvidia-glcore.so.$NVIDIA_VERSION:"
	ROOTFS_KEEPERS+="libnvidia-compiler.so.$NVIDIA_VERSION:"
	ROOTFS_KEEPERS+="libnvidia-cfg.so.$NVIDIA_VERSION:"
	ROOTFS_KEEPERS+="libnvidia-tls.so.$NVIDIA_VERSION:"
}
uncompress-nvidia() {
	echo nvidia: $*
	sh $2 -x
}

configure-nvidia() {
	# if modules were reinstalled, we need to rebuild too
	if [ -e ._conf_nvidia -a \
		../linux/._install_linux-modules -nt ._conf_nvidia ]; then 
		rm -f ._conf_nvidia
	fi
	configure echo Configure nvidia
}

compile-nvidia-local() {
	( pushd $NVIDIA_NAME/kernel
		set -x
		$MAKE \
			NVDEBUG=1 \
			SYSOUT="$BUILD/linux-obj" \
			SYSSRC="$BUILD/linux" \
			CC=$GCC \
			HOST_CC=gcc \
				$1 || exit 1
	) || {
		echo "### Error building $PACKAGE!"
		exit 1
	}
}

compile-nvidia() {
	compile compile-nvidia-local module
}

install-nvidia-local() {
	set -x
	pushd $NVIDIA_NAME/
	mkdir -p "$BUILD"/kernel/lib/modules/$(hget linux version)/kernel/drivers/video/
	cp kernel/nvidia.ko "$BUILD"/kernel/lib/modules/$(hget linux version)/kernel/drivers/video/
	sh "$PATCHES/nvidia/nvidia-minifs-installer.sh" >../._nvidia_install.sh
	DESTDIR="$STAGING_USR" installwatch -o ../._dist_$PACKAGE.log bash ../._nvidia_install.sh
	ln -sf libGL.so.1 "$STAGING_USR"/lib/libGL.so.1.2
	popd
	set +x
}

install-nvidia() {
	log_install install-nvidia-local
}

deploy-nvidia() {
	mkdir -p "$ROOTFS"/etc/X11
	deploy deploy_binaries
}
