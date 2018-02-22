
PACKAGES+=" libares"
hset libares url "https://c-ares.haxx.se/download/c-ares-1.14.0.tar.gz"

PACKAGES+=" mosquitto"
hset mosquitto url "http://mosquitto.org/files/source/mosquitto-1.4.14.tar.gz"
hset mosquitto depends "libares openssl util-linux"
hset mosquitto destdir "$STAGING_USR"

configure-mosquitto-local() {

	configure-generic
}

configure-mosquitto() {
	configure configure-mosquitto-local
}

compile-mosquitto() {
	export LDFLAGS="$LDFLAGS_RLINK"
	compile-generic CROSS_COMPILE=$TARGET_FULL_ARCH
	export LDFLAGS="$LDFLAGS_BASE"
}

install-mosquitto() {
	install-generic prefix= CROSS_COMPILE="$TARGET_FULL_ARCH-"
}

deploy-mosquitto() {
	deploy deploy_binaries
}
