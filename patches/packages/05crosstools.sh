
if [ ! -f "$GCC" ]; then 
	PACKAGES="$PACKAGES crosstools"
	NEED_CROSSTOOLS="crosstools"
fi
hset url crosstools	"http://ymorin.is-a-geek.org/download/crosstool-ng/crosstool-ng-${VERSION_crosstools}.tar.bz2" 

configure-crosstools() {
	# this patch is needed on newer host kernels
	for pd in "$PATCHES/uclibc" "$PATCHES/uclibc-${TARGET_BOARD}"; do
		if [ -d $pd ]; then
			echo "##### Installing $pd patches"
			cp $pd/*.patch /patches/uClibc/0.9.30.1/
		fi
	done

	configure ./configure --prefix="$STAGING" &&
		$MAKE &&
		$MAKE install

	mkdir -p "$TOOLCHAIN"
	if [ ! -f "$TOOLCHAIN"/.config ]; then
		for cf in "$CONFIG"/config_crosstools.conf "$CONFIG"/config_uclibc.conf ; do
			dst=$(basename $cf)
			cat $cf | sed \
				-e "s|MINIFS_TOOLCHAIN|$TOOLCHAIN|g" \
				-e "s|MINIFS_ROOT|$BASE|g" \
				-e "s|MINIFS_STAGING|$STAGING|g" \
				-e "s|MINIFS_KERNEL|$KERNEL|g" \
				 >"$TOOLCHAIN"/$dst
		done
	fi
	pushd "$TOOLCHAIN"
		cp config_crosstools.conf .config
		"$STAGING"/bin/ct-ng build
		#"$STAGING"/bin/ct-ng build.4
	popd
}

compile-crosstools() {
	compile echo Done
}

# installing crosstools is just the beginning!
install-crosstools() {
	if [ ! -f "$GCC" ]; then 
		echo "GCC doesn't exists!!"
		exit 1
	fi
	log_install echo Done
}

