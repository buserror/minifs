
PACKAGES+=" bfd"
hset bfd url "http://ftp.gnu.org/gnu/binutils/binutils-2.19.1.tar.bz2"

configure-bfd() {
 configure-generic --prefix=/usr --enable-shared  --enable-install-libbfd --enable-install-libiberty \
    --enable-install-libintl --disable-nls --disable-poison-system-directories 
 cd libiberty; configure-generic --disable-werror --prefix=/usr; cd ..
 cd bfd; configure-generic --disable-werror --prefix=/usr; cd ..
}

compile-bfd() {
# compile $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS -fPIC" CONFIG_PREFIX="$ROOTFS" 
 cd libiberty;  $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS -fPIC" CONFIG_PREFIX="$ROOTFS" ; cd .. 
 compile $MAKE -C bfd  CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS -fPIC" CONFIG_PREFIX="$ROOTFS" 
}

install-bfd() {
  cp include/libiberty.h $STAGING_USR/include/
  cp libiberty/libiberty.a $STAGING_USR/lib
  cd bfd; $MAKE install ; cd ..
# cp bfd/libbfd* $STAGING_USR/lib/
# cp bfd/bfd.h* $STAGING_USR/include/
# cp include/symcat.h* $STAGING_USR/include/
}

#PACKAGES+=" libiberty"
#hset libiberty  url "https://toolbox-of-eric.googlecode.com/files/libiberty.tar.gz"

#configure-libiberty() {
# configure-generic --prefix=/usr
#}

#compile-libiberty() {
# compile $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS -fPIC" CONFIG_PREFIX="$ROOTFS"
#}

install-libiberty() {
 cp include/* $STAGING_USR/include/
 cp libiberty/libiberty.a $STAGING_USR/lib
}

PACKAGES+=" popt"
hset popt url "http://rpm5.org/files/popt/popt-1.16.tar.gz"

configure-popt() {
 configure-generic --prefix=/usr
}
compile-popt() {
 compile $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS -fPIC" CONFIG_PREFIX="$ROOTFS"
}
install-popt() {
 $MAKE install  
 cp $STAGING_USR/lib/libpopt.so.0.0.0   $STAGING_USR/lib/libpopt.so
}

PACKAGES+=" oprofile"
hset oprofile url "http://prdownloads.sourceforge.net/oprofile/oprofile-0.9.9.tar.gz"
hset oprofile depends "bfd popt libiberty"

configure-oprofile() {
	configure-generic --prefix=/usr   --with-kernel-support --with-linux=$KERNEL  \
   --disable-optimization   --disable-werror  \
   --with-extra-libs=$BASE/toolchain/mips-octeon-linux-uclibc/mips-octeon-linux-uclibc/sysroot/lib/libpthread.so.0 \
   --with-binutils=$BUILD/bfd
}

compile-oprofile() {
   MYLDFLAG="$LDFLAGS $LDFLAGS_BASE $BASE/toolchain/mips-octeon-linux-uclibc/mips-octeon-linux-uclibc/sysroot/lib/libpthread.so.0"
   $MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" LDFLAGS="$MYLDFLAG" CONFIG_PREFIX="$ROOTFS"
  # compile #$MAKE CROSS_COMPILE="${CROSS}-" CFLAGS="$TARGET_CFLAGS" CONFIG_PREFIX="$ROOTFS"
}


install-oprofile () {
 $MAKE install DESTDIR=$STAGING  
}

deploy-oprofile () {
# cp -f $STAGING/usr/bin/*op*  $ROOTFS/usr/bin
# cp -f $STAGING/usr/lib/libpopt.so $ROOTFS/usr/lib/libpopt.so.0
# cp -f $STAGING/usr/lib/libbfd.a $ROOTFS/usr/lib
# cp -f $STAGING/usr/lib/libiberty.a $ROOTFS/usr/lib
# cp -f $BASE/toolchain/mips-octeon-linux-uclibc/mips-octeon-linux-uclibc/sysroot/lib/libpthread.so.0 $ROOTFS/usr/lib

 OPDIR=$STAGING/usr/local/oprofile_install
 rm -rf $OPDIR
 mkdir -p $OPDIR
 mkdir -p $OPDIR/usr/bin
 mkdir -p $OPDIR/usr/lib

 cp -f $STAGING/usr/bin/*op*  $OPDIR/usr/bin
 cp -f $STAGING/usr/lib/libpopt.so $OPDIR/usr/lib/libpopt.so.0
 cp -f $STAGING/usr/lib/libbfd.a $OPDIR/usr/lib
 cp -f $STAGING/usr/lib/libiberty.a $OPDIR/usr/lib
 cp -rf $STAGING/usr/lib/oprofile $OPDIR/usr/lib/
 cp -f $BASE/toolchain/mips-octeon-linux-uclibc/mips-octeon-linux-uclibc/sysroot/lib/libpthread.so.0 $OPDIR/usr/lib
 cp -f $BASE/toolchain/mips-octeon-linux-uclibc/mips-octeon-linux-uclibc/sysroot/lib/libstdc++.so.6 $OPDIR/usr/lib
 cp -f $BASE/../vega_firmware/Vegas2/Runtime/abs/vegas2.x $OPDIR/vega

 home=$(pwd)
 cd  $OPDIR
 tar cfz oprofile.tgz *
 cd $home

}



