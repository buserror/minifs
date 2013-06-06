
PACKAGES+=" urjtag"
hset urjtag url "git!git://urjtag.git.sourceforge.net/gitroot/urjtag/urjtag#urjtag-git.tar.bz2"
hset urjtag dir "urjtag/urjtag"

patch-urjtag() {
	echo patch-urjtag
	cd urjtag
	local v=$(gettext --version | sed -n -r 's/.*\s([0-9]*\.[0-9]*\.[0-9]*)$/\1/p')
	sed -i -e "s|^AM_GNU_GETTEXT_VERSION.*$|AM_GNU_GETTEXT_VERSION([$v])|" configure.ac
}
configure-urjtag() {
	configure-generic \
		--without-readline --without-libusb --without-libftdi \
		--disable-python --disable-bus --disable-bsdl \
		--enable-cable=gpio \
		--enable-lowlevel=direct
}
deploy-urjtag() {
	deploy deploy_binaries
}
