
PACKAGES+=" rrdtool"
hset rrdtool url "http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.4.7.tar.gz"
hset rrdtool depends "libpango libxml2"

configure-rrdtool() {
	export LDFLAGS="$LDFLAGS_RLINK"
	configure-generic --disable-nls --disable-perl --disable-lua rd_cv_ieee_works=yes
	export LDFLAGS="$LDFLAGS_BASE"
}

deploy-rrdtool() {
	deploy deploy_binaries
}
