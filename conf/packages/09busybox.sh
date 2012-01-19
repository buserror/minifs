
PACKAGES="$PACKAGES busybox"
hset busybox url "http://busybox.net/downloads/busybox-$(hget busybox version).tar.bz2"
hset busybox depends "crosstools libtool"

configure-busybox() {
	if [ -f "$CONFIG"/config_busybox.conf ]; then
		configure cp -a  "$CONFIG"/config_busybox.conf .config
	else
		configure $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" defconfig
		COMMAND="busybox_menuconfig"
	fi
	if [ "$COMMAND_PACKAGE" = "busybox" ] ; then
		$MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" $COMMAND_TARGET

		echo #### busybox config done, copying it back
		cp .config "$CONFIG"/config_busybox.conf
		rm ._*
		exit 0
	fi
}

compile-busybox() {
	compile $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" -j8
}

install-busybox() {
	log_install echo Done
}

deploy-busybox() {
	deploy $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS" install
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
	echo "minifs-$MINIFS_BOARD-" | \
		awk '{ print $0 strftime("%Y%m%d%H%M"); }' \
			>$ROOTFS/etc/minifs.tag
			
	## Add rootfs overrides for boards
	for pd in "$CONFIG/rootfs" $(minifs_path_split "rootfs"); do
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
