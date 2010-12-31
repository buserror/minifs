
PACKAGES+=" ppp"
hset ppp url "ftp://ftp.samba.org/pub/ppp/ppp-2.4.1.tar.gz"


deploy-ppp() {
        deploy cp $(get_installed_binaries) "$ROOTFS"/usr/bin/
	deploy_staging_path "/etc/bluetooth"
}

