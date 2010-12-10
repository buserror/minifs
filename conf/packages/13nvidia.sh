
NVIDIA_VERSION=260.19.21
NVIDIA_NAME=NVIDIA-Linux-x86-${NVIDIA_VERSION}
PACKAGES+=" nvidia"
hset nvidia url "http://us.download.nvidia.com/XFree86/Linux-x86/$NVIDIA_VERSION/$NVIDIA_NAME.run"
hset nvidia depends "xorgserver linux-modules"

uncompress-nvidia() {
	echo nvidia: $*
	sh $2 -x
}

configure-nvidia() {
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
	) || exit 1
}

compile-nvidia() {
	compile compile-nvidia-local module
}

install-nvidia-local() {
	set -x
	pushd $NVIDIA_NAME/kernel
	mkdir -p "$BUILD"/kernel/lib/modules/$(hget linux version)/kernel/drivers/video/
	cp nvidia.ko "$BUILD"/kernel/lib/modules/$(hget linux version)/kernel/drivers/video/
	popd
	set +x
}

install-nvidia() {
	log_install install-nvidia-local
}

