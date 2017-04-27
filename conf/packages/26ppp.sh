
PACKAGES+=" ppp"
hset ppp url "ftp://ftp.samba.org/pub/ppp/ppp-2.4.1.tar.gz"
hset ppp depends "busybox"

install-ppp() {
	install-generic
	chmod 0755 $(get_installed_binaries)
}

deploy-ppp() {
	deploy deploy_binaries
}

PACKAGES+=" lrzsz"
hset lrzsz url "http://http.debian.net/debian/pool/main/l/lrzsz/lrzsz_0.12.21.orig.tar.gz"
hset lrzsz depends "busybox"

deploy-lrzsz() {
	deploy deploy_binaries
}
