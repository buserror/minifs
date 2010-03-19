
NVIDIA_VERSION=190.53
NVIDIA_NAME=NVIDIA-Linux-x86-${NVIDIA_VERSION}-pkg1
PACKAGES+=" nvidia"
hset url nvidia "http://us.download.nvidia.com/XFree86/Linux-x86/190.53/$NVIDIA_NAME.run"

uncompress-nvidia() {
	echo nvidia: $*
	sh $2 -x
}

configure-nvidia() {
	configure echo Configure nvidia
	pushd $NVIDIA_NAME/usr/src/nv
	popd
}

compile-nvidia() {
	echo Compile nvidia
	( pushd $NVIDIA_NAME/usr/src/nv
		set -x
		$MAKE NVDEBUG=1 \
			SYSOUT="$BUILD/linux-obj" \
			SYSSRC="$BUILD/linux" \
			CC=$GCC \
			HOST_CC=gcc \
				module || exit 1
	) || exit 1
}

install-nvidia() {
	echo Install nVidia
}

