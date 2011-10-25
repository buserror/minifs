#######################################################################
## contains the 4 main phases of compiling the kernel
#######################################################################

hset linux url "http://www.kernel.org/pub/linux/kernel/v$(hget linux version | awk -F. '{print $1 "." $2;}')/linux-$(hget linux version).tar.bz2"
hset linux targets "linux-headers linux-modules linux-bare linux-initrd"

hset linux-headers dir "linux"
hset linux-modules dir "linux"
hset linux-bare dir "linux"
hset linux-initrd dir "linux"

# the headers gets installed first, the other phases are later
PACKAGES+=" linux-headers"

export TARGET_KERNEL_ARCH="${TARGET_KERNEL_ARCH:-$TARGET_ARCH}"

#######################################################################
## linux-headers
#######################################################################

setup-linux-headers() {
	mkdir -p "$BUILD/linux-obj"
	if [ "$COMMAND_PACKAGE" = "kernel" -o "$COMMAND_PACKAGE" = "linux" ] ; then
		cp "$CONFIG/config_kernel.conf"  "$BUILD/linux-obj"/.config
		$MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
			CROSS_COMPILE="${CROSS}-" \
				$COMMAND_TARGET
		cp "$BUILD/linux-obj/.config" "$CONFIG/config_kernel.conf"
		rm -f ._*
		exit
	fi
	if [ ! -f "$BUILD/linux-obj/.config-bare" -o \
		"$CONFIG/config_kernel.conf" -nt "$BUILD/linux-obj/.config-bare" ]; then
		echo setup-linux-headers
		sed -e "s/CONFIG_INITRAMFS_SOURCE=.*/CONFIG_INITRAMFS_SOURCE=\"\"/" \
			"$CONFIG/config_kernel.conf" \
			>"$BUILD"/linux-obj/.config-bare
		rm -f ._conf_linux-headers
	fi
	ln -sf ".config-bare" "$BUILD/linux-obj/.config"
}

configure-linux-headers() {
	configure echo Done
}

compile-linux-headers() {
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			oldconfig			
}

install-linux-headers-local() {
	$MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_HDR_PATH="$KERNEL" \
			headers_install
	rm -rf "$STAGING_USR"/include/linux || true
	ln -s "$KERNEL"/include/linux \
		"$STAGING_USR"/include/linux || true
}

install-linux-headers() {
	log_install install-linux-headers-local
}

#######################################################################
## linux-modules
#######################################################################
if [ "$CONFIG_MODULES" != "" ]; then
	PACKAGES+=" linux-modules"
fi

hset linux-modules depends "linux-headers crosstools"
	
setup-linux-modules() {
	if [ "$BUILD/linux-obj/.config-bare" -nt ._conf_linux-bare ]; then		
		rm -f ._conf_linux-modules ._conf_linux-bare
	fi
}

configure-linux-modules() {
	configure echo Done
}

compile-linux-modules() {
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			modules -j4
}

install-linux-modules() {
	log_install $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_HDR_PATH="$KERNEL" INSTALL_MOD_PATH="$KERNEL" \
			modules_install 
}
deploy-linux-modules() {
	deploy rsync -a --exclude source --exclude build "$KERNEL"/lib "$ROOTFS/"
	find "$ROOTFS"/lib/modules/ -name \*.ko | \
		xargs "${CROSS}-strip" -R .note -R .comment --strip-unneeded
}

#######################################################################
## linux-bare
#######################################################################

PACKAGES+=" linux-bare"
hset linux-bare depends "linux-modules linux-headers crosstools uboot"

configure-linux-bare() {
	configure echo Done
}
compile-linux-bare() {
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			$TARGET_KERNEL_NAME -j4
}
install-linux-bare() {
	log_install $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_PATH="$KERNEL" INSTALL_MOD_PATH="$KERNEL" \
		INSTALLKERNEL="no-default-install" \
			install
}
deploy-linux-bare() {
	if [ -f "$BUILD"/linux-obj/arch/$TARGET_KERNEL_ARCH/boot/bzImage ]; then
		deploy cp "$BUILD"/linux-obj/arch/$TARGET_KERNEL_ARCH/boot/bzImage \
			"$BUILD"/vmlinuz-bare.bin
	elif [ -f "$BUILD"/linux-obj/arch/$TARGET_KERNEL_ARCH/boot/uImage ]; then
		deploy dd if="$BUILD"/linux-obj/arch/arm/boot/uImage \
			of="$BUILD"/kernel.ub \
			bs=128k conv=sync
	fi
}

#######################################################################
## linux-initrd
#######################################################################
if [ $TARGET_INITRD -eq 1 ]; then
	PACKAGES+=" linux-initrd"
fi
hset linux-initrd depends "filesystems"
hset linux-initrd phases "deploy"

setup-linux-initrd() {
	mkdir -p "$BUILD/linux-obj"
	touch ._conf_linux-initrd
	if [ ! -f "$BUILD/linux-obj/.config-initrd" -o \
		"$CONFIG/config_kernel.conf" -nt "$BUILD/linux-obj/.config-initrd" ]; then
		sed -e 's|CONFIG_INITRAMFS_SOURCE=.*|CONFIG_INITRAMFS_SOURCE="../rootfs ../staging-tools/special_file_table_kernel.txt"|' \
			"$CONFIG/config_kernel.conf" \
			>"$BUILD"/linux-obj/.config-initrd
		rm -f ._conf_linux-initrd
	fi
	ln -sf ".config-initrd" "$BUILD/linux-obj/.config"
}

configure-linux-initrd() {
	configure $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			oldconfig >>"$LOGFILE" 2>&1
}

compile-linux-initrd() {
	rm -f "$BUILD/linux-obj"/usr/initramfs_data.*
	compile $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
			$TARGET_KERNEL_NAME -j4
}
install-linux-initrd() {
	log_install $MAKE CFLAGS="$TARGET_CFLAGS" ARCH=$TARGET_KERNEL_ARCH O="$BUILD/linux-obj" \
		CROSS_COMPILE="${CROSS}-" \
		INSTALL_PATH="$KERNEL" INSTALL_MOD_PATH="$KERNEL" \
		INSTALLKERNEL="no-default-install" \
			install
}

deploy-linux-initrd() {
	setup-linux-initrd && \
		configure-linux-initrd && \
		compile-linux-initrd && \
		install-linux-initrd
	if [ -f "$BUILD"/linux-obj/arch/$TARGET_KERNEL_ARCH/boot/bzImage ]; then
		deploy cp "$BUILD"/linux-obj/arch/$TARGET_KERNEL_ARCH/boot/bzImage \
			"$BUILD"/vmlinuz-full.bin
	elif [ -f "$BUILD"/linux-obj/arch/$TARGET_KERNEL_ARCH/boot/uImage ]; then
		deploy dd if="$BUILD"/linux-obj/arch/arm/boot/uImage \
			of="$BUILD"/kernel-initrd.ub \
			bs=128k conv=sync 
	fi
}

PACKAGES+=" linux-firmware"
hset linux-firmware url "git!git://git.kernel.org/pub/scm/linux/kernel/git/romieu/linux-firmware.git#linux-firmware-110906-git.tar.bz2"
hset linux-firmware depends "linux-modules"
hset linux-firmware phases "none"

PACKAGES+=" firmware-rtl"
hset firmware-rtl depends "linux-firmware"
hset firmware-rtl dir "linux-firmware"
hset firmware-rtl url "none"
hset firmware-rtl phases "deploy"

deploy-firmware-rtl-local() {
	mkdir "$ROOTFS"/lib/firmware
	cp -r rtl_nic/ "$ROOTFS"/lib/firmware/
}
deploy-firmware-rtl() {
	if [ ! -f "._install_$PACKAGE" ]; then
		touch "._install_$PACKAGE"
	fi
	deploy deploy-firmware-rtl-local
}
