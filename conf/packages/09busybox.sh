
PACKAGES="$PACKAGES busybox"
hset busybox version "1.29.1"
hset busybox url "http://busybox.net/downloads/busybox-$(hget busybox version).tar.bz2"
hset busybox depends "crosstools host-libtool"
hset busybox optional "pam"

configure-busybox() {
	local obj=$STAGING/obj/busybox-obj
	mkdir -p $obj
	if [ -f "$CONFIG"/config_busybox.conf ]; then
		configure cp -a  "$CONFIG"/config_busybox.conf $obj/.config
	else
		configure $MAKE O=$obj CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" defconfig
		COMMAND="busybox_menuconfig"
	fi
	if [ "$COMMAND_PACKAGE" = "busybox" ] ; then
		$MAKE O=$obj CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" $COMMAND_TARGET

		echo #### busybox config done, copying it back
		cp $obj/.config "$CONFIG"/config_busybox.conf
		rm ._*
		exit 0
	fi
}

compile-busybox() {
	local obj=$STAGING/obj/busybox-obj
	compile $MAKE O=$obj CROSS_COMPILE="${CROSS}-" \
		CFLAGS="$TARGET_CFLAGS" \
		CONFIG_PREFIX="$ROOTFS" \
		$MAKE_ARGUMENTS
}

install-busybox() {
	log_install echo Done
}

deploy-busybox-local() {
	local obj=$STAGING/obj/busybox-obj
	$MAKE O=$obj CROSS_COMPILE="${CROSS}-" \
		CFLAGS="$TARGET_CFLAGS" \
		CONFIG_PREFIX="$ROOTFS" install
}

deploy-busybox() {
	deploy deploy-busybox-local
}

PACKAGES+=" filesystem-populate"
hset filesystem-populate url "none"
hset filesystem-populate dir "."
hset filesystem-populate phases "deploy"
hset filesystem-populate depends "busybox"

deploy-filesystem-populate() {
	deploy echo Copying
	echo -n "    Populating filesystem... "
	(
	mkdir -p "$ROOTFS"/proc/ "$ROOTFS"/dev/ "$ROOTFS"/sys/ \
		"$ROOTFS"/tmp/ "$ROOTFS"/var/run "$ROOTFS"/var/log
	rsync -av \
		--exclude=._\* \
		"$STAGING/etc/" \
		"$STAGING_USR/etc/" \
		"$ROOTFS/etc/"
	mv "$ROOTFS"/usr/etc/* "$ROOTFS"/etc/
	rm -rf "$ROOTFS"/usr/etc/ "$ROOTFS"/usr/var/
	ln -s ../etc $ROOTFS/usr/etc
	ln -s ../var $ROOTFS/usr/var
	echo minifs-$MINIFS_BOARD >$ROOTFS/etc/hostname
	tag=$(echo "minifs-$MINIFS_BOARD-" | \
		awk '{ print $0 strftime("%y%m%d%H%M"); }')
	echo $tag >$ROOTFS/etc/minifs.tag
	export MINIFS_TAG=$tag

	## Add rootfs overrides for boards
	for pd in $(minifs_locate_config_path rootfs 1); do
		if [ -d "$pd" ]; then
			echo "### Overriding root $pd"
			rsync -av --exclude=._\* "$pd/" "$ROOTFS/"
		fi
	done

	) >>"$LOGFILE" 2>&1 || {
		echo "FAILED"; exit 1
	}
	echo "Done"
}
