#######################################################################
## contains the 4 main phases of compiling the kernel
#######################################################################

hput dir linux-headers "linux"
hput dir linux-modules "linux"
hput dir linux-bare "linux"
hput dir linux-initrd "linux"

# the headers gets installed first, the other phases are later
PACKAGES="$PACKAGES linux-headers"

#######################################################################
## linux-headers
#######################################################################

configure-linux-headers() {
	mkdir -p "$BUILD/linux-obj"
	# Installing default kernel config
	cp "$CONFIG/config_kernel.conf"  "$BUILD/linux-obj"/.config

	if [ "$COMMAND" = "kernel_menuconfig" ] ; then
		$MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
			CROSS_COMPILE="${CROSS}-" \
				menuconfig
		cp "$BUILD/linux-obj/.config" "$CONFIG/config_kernel.conf"
		rm -f ._*
		exit
	fi
	configure echo Done
}

compile-linux-headers() {
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			oldconfig
}

install-linux-headers() {
	log_install $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_HDR_PATH="$KERNEL" \
			headers_install
}

#######################################################################
## linux-modules
#######################################################################

configure-linux-modules() {
	configure echo Done
}

compile-linux-modules() {
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			modules -j4
}

install-linux-modules() {
	log_install $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_HDR_PATH="$KERNEL" INSTALL_MOD_PATH="$KERNEL" \
			modules_install 
}
deploy-linux-modules() {
	deploy rsync -a "$KERNEL"/lib "$ROOTFS/"
	find "$ROOTFS"/lib/modules/ -name \*.ko | xargs "${CROSS}-strip" -R .note -R .comment --strip-unneeded
}

#######################################################################
## linux-bare
#######################################################################

configure-linux-bare() {
	sed -i "s/CONFIG_INITRAMFS_SOURCE=.*/CONFIG_INITRAMFS_SOURCE=\"\"/" \
		"$BUILD"/linux-obj/.config 
	configure echo Done
	touch ._conf_linux-bare
}

compile-linux-bare() {
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			$TARGET_KERNEL_NAME -j4
}

install-linux-bare() {
	log_install $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_PATH="$KERNEL" INSTALL_MOD_PATH="$KERNEL" \
			install
}
deploy-linux-bare() {
	if [ -f "$BUILD"/linux-obj/arch/$TARGET_ARCH/boot/bzImage ]; then
		deploy cp "$BUILD"/linux-obj/arch/$TARGET_ARCH/boot/bzImage \
			"$BUILD"/vmlinuz-bare.bin
	elif [ -f "$BUILD"/linux-obj/arch/$TARGET_ARCH/boot/uImage ]; then
		deploy dd if="$BUILD"/linux-obj/arch/arm/boot/uImage \
			of="$BUILD"/kernel.ub \
			bs=128k conv=sync
	fi
}

#######################################################################
## linux-initrd
#######################################################################

configure-linux-initrd() {
	configure echo Done 
	cp "$CONFIG/config_kernel.conf"  "$BUILD/linux-obj"/.config
	$MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			oldconfig >>"$LOGFILE" 2>&1
	touch ._conf_linux-initrd
}

compile-linux-initrd() {
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			$TARGET_KERNEL_NAME -j4
}

install-linux-initrd() {
	log_install $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_PATH="$KERNEL" INSTALL_MOD_PATH="$KERNEL" \
			install
}
deploy-linux-initrd() {
	if [ -f "$BUILD"/linux-obj/arch/$TARGET_ARCH/boot/bzImage ]; then
		deploy cp "$BUILD"/linux-obj/arch/$TARGET_ARCH/boot/bzImage \
			"$BUILD"/vmlinuz-full.bin
	elif [ -f "$BUILD"/linux-obj/arch/$TARGET_ARCH/boot/uImage ]; then
		deploy dd if="$BUILD"/linux-obj/arch/arm/boot/uImage \
			of="$BUILD"/kernel-initrd.ub \
			bs=128k conv=sync 
	fi
}

