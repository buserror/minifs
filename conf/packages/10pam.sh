#######################################################################
## pam
#######################################################################
PACKAGES+=" pam"

V="1.3.1"
hset pam version $V
#hset pam url "http://www.linux-pam.org/library/Linux-PAM-$V.tar.bz2"
# seems dev has moved to github for 1.3.1
hset pam url "https://github.com/linux-pam/linux-pam/releases/download/v$V/Linux-PAM-$V.tar.xz"
hset pam prefix "/"

configure-pam-local() {
    # no need for that, this is done automagically
#    cat $PATCHES/pam/fix-have-getdomainname.patch | patch -p1
    # "@"
    rm -f configure
    configure-generic-local --with-pic --enable-static \
        --disable-nls --disable-selinux --enable-db=no \
        --disable-cracklib --disable-nis --disable-audit \
        --disable-regenerate-docu
}

configure-pam() {
	if [ "$TARGET_SHARED" -eq 0 ]; then
		configure configure-pam-local \
			--disable-shared LDFLAGS=-static
	else
		configure configure-pam-local
	fi
}

compile-pam() {
    compile $MAKE -j8
}

install-pam-local() {
    mkdir -p \
        "$STAGING_USR/lib" \
        "$STAGING_USR/lib/security" \
        "$STAGING_USR/usr/include/security"

    cp -P \
        libpam/.libs/libpam.so* libpam_misc/.libs/libpam_misc.so* libpamc/.libs/libpamc.so* \
        libpam/.libs/libpam.a   libpam_misc/.libs/libpam_misc.a   libpamc/.libs/libpamc.a \
        "$STAGING_USR"/lib/

    cp \
        modules/pam_listfile/.libs/pam_listfile.so \
        modules/pam_limits/.libs/pam_limits.so \
        modules/pam_unix/.libs/pam_unix.so \
        modules/pam_time/.libs/pam_time.so \
        modules/pam_wheel/.libs/pam_wheel.so \
        modules/pam_group/.libs/pam_group.so \
        modules/pam_warn/.libs/pam_warn.so \
        modules/pam_deny/.libs/pam_deny.so \
        modules/pam_shells/.libs/pam_shells.so \
        modules/pam_securetty/.libs/pam_securetty.so \
        modules/pam_rootok/.libs/pam_rootok.so \
        modules/pam_nologin/.libs/pam_nologin.so \
    "$STAGING_USR"/lib/security/

    cp $(pwd)/libpam/include/security/* \
       $(pwd)/libpamc/include/security/* \
       $(pwd)/libpam_misc/include/security/* \
       "$STAGING_USR"/usr/include/security/
}

install-pam() {
    log_install install-pam-local
}

deploy-pam-local() {
    mkdir -p \
        "$ROOTFS/lib/security"

    cp -P "$STAGING_USR"/lib/libpam* "$ROOTFS"/lib/
    cp "$STAGING_USR"/lib/security/*.so "$ROOTFS"/lib/security/
}

deploy-pam() {
    deploy deploy-pam-local
}

