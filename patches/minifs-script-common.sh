

#######################################################################
## zlib
#######################################################################

if [ -d "$BUILD/zlib" ]; then
package zlib
	configure ./configure \
		--prefix="$STAGING"  &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" \
		CC="$GCC" CFLAGS="$TARGET_CFLAGS" && 
	install $MAKE install PATH="$STAGING/bin:$PATH" \
		CC="$GCC"
end_package
fi


#######################################################################
## lzo (for mtd-utils)
#######################################################################

if [ -d "$BUILD/lzo" ]; then
package lzo
	configure ./configure \
		--prefix="$STAGING" \
		--host=$TARGET_FULL_ARCH \
		--enable-static --disable-shared \
		CC="$GCC" CFLAGS="$TARGET_CFLAGS" &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" \
		CC="$GCC" && 
	install $MAKE install PATH="$STAGING/bin:$PATH" \
		CC="$GCC"
end_package
fi

#######################################################################
## e2fdlibs (for mtd-utils)
#######################################################################

if [ -d "$BUILD/e2fsprogs" ]; then
package e2fsprogs
	configure ./configure \
		--prefix="$STAGING" \
		--disable-tls \
		--host=$TARGET_FULL_ARCH \
		--enable-static --disable-shared \
		CC="$GCC" CFLAGS="$TARGET_CFLAGS"  &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" \
		CC="$GCC" && 
	install $MAKE install PATH="$STAGING/bin:$PATH" \
		CC="$GCC"
end_package
fi

#######################################################################
## screen
#######################################################################

if [ -d "$BUILD/screen" ]; then
package screen
	configure ./configure --enable-static --disable-shared \
		--prefix="$ROOTFS" \
		--host=$TARGET_FULL_ARCH \
		PATH="$STAGING/bin:$PATH" \
		CC="$GCC" CFLAGS="$TARGET_CFLAGS" &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	install $MAKE install PATH="$STAGING/bin:$PATH"
end_package
fi

#######################################################################
## i2c-tools
#######################################################################
if [ -d "$BUILD/i2c" ]; then
package i2c
	configure echo Done &&
	compile $MAKE CC="$GCC" CFLAGS="$TARGET_CFLAGS" LDFLAGS="-static" &&
	install cp ./tools/i2c{detect,dump,get,set} "$ROOTFS/bin/"
end_package
fi

#######################################################################
## libusb
#######################################################################
if [ -d "$BUILD/libusb" ]; then
package libusb
	configure ./configure --enable-static --disable-shared \
		--prefix="$STAGING" \
		--host=$TARGET_FULL_ARCH \
		PATH="$STAGING/bin:$PATH" \
		CC="$GCC" CFLAGS="$TARGET_CFLAGS" &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	install $MAKE install PATH="$STAGING/bin:$PATH"
#	cp "$STAGING/include/libusb*/libusb.h" "$STAGING"/include/usb.h
end_package
fi

#######################################################################
## mtd_utils
#######################################################################
if [ -d "$BUILD/mtd_utils" ]; then
package mtd_utils
	configure echo Done &&
	compile $MAKE CC="$GCC" CFLAGS="$TARGET_CFLAGS -I$STAGING/include -DWITHOUT_XATTR" \
		LDFLAGS="-L$STAGING/lib -static" &&
	install cp nandwrite mtd_debug  "$ROOTFS/bin/"
end_package
fi

#######################################################################
## libftdi
#######################################################################
if [ -d "$BUILD/libftdi" ]; then
package libftdi
	configure  ./configure --enable-static --disable-shared \
		--prefix="$STAGING" \
		--host=$TARGET_FULL_ARCH \
		--disable-libftdipp --with-async-mode \
		PATH="$STAGING/bin:$PATH" \
		CC="$GCC" CFLAGS="$TARGET_CFLAGS" CPPFLAGS="-I$STAGING/include" &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	install $MAKE install PATH="$STAGING/bin:$PATH"
end_package
fi

#######################################################################
## dropbear
#######################################################################

if [ -d "$BUILD/dropbear" ]; then
package dropbear
	configure ./configure --enable-static --disable-shared \
		--prefix="$ROOTFS" \
		--host=$TARGET_FULL_ARCH \
		--with-zlib="$STAGING" \
		PATH="$STAGING/bin:$PATH" \
		CC="$GCC" \
		CFLAGS="-static -Os ${TARGET_CFLAGS}" \
		LDFLAGS="-static" &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	install $MAKE install PATH="$STAGING/bin:$PATH"

	mkdir -p "$ROOTFS/etc/dropbear"
	if [ $TARGET_ARCH = "i386" ]; then	
		if [ ! -f "$BUILD"/dropbear_dss_host_key ]; then
			echo "#### generating new dropbear keys"
			"$ROOTFS"/bin/dropbearkey -t dss -f "$BUILD"/dropbear_dss_host_key
			"$ROOTFS"/bin/dropbearkey -t rsa -f "$BUILD"/dropbear_rsa_host_key
		fi
	fi
	cp "$BUILD"/dropbear_*_host_key "$ROOTFS"/etc/dropbear/
end_package
fi

#######################################################################
## Jpeg
#######################################################################

if [ -d "$BUILD/jpegsrc" ]; then
package jpegsrc
	configure ./configure --enable-static --disable-shared \
		--prefix="$STAGING" \
		--host=$TARGET_FULL_ARCH \
		PATH="$STAGING/bin:$PATH" \
		CC="$GCC" CFLAGS="$TARGET_CFLAGS"  &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	install $MAKE install PATH="$STAGING/bin:$PATH"
end_package
fi

if [ -d "$BUILD/ffmpeg" ]; then
package ffmpeg
	configure ./configure --enable-static --disable-shared \
		--prefix="$STAGING" \
		--enable-cross-compile \
		--sysroot="$STAGING" \
		--arch=i486 \
		--cross-prefix="${CROSS}-" \
		--host-cc="$GCC" \
		--disable-ffplay --disable-ffserver \
		--enable-gpl --enable-swscale --enable-pthreads \
		--enable-fastdiv --enable-small \
		--enable-hardcoded-tables  \
		 --disable-mmx --disable-mmx2  --disable-sse --disable-ssse3 \
		 CC="$GCC" \
		 PATH="$STAGING/bin:$PATH" CFLAGS="$TARGET_CFLAGS" &&
	compile $MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	install $MAKE install PATH="$STAGING/bin:$PATH"
end_package
fi

if [ -d "$BUILD/mjpg" ]; then
package mjpg
	mkdir -p "$ROOTFS"/opt/
	configure echo Done &&
	compile $MAKE CC="$GCC" \
		EXTRA_LDFLAGS="-L $STAGING/lib" \
		EXTRA_CFLAGS="-Os -I$STAGING/include $TARGET_CFLAGS" \
		STATIC=1 &&
	install cp -ra mjpg_streamer www "$ROOTFS"/opt/ &&
	"${CROSS}-strip" "$ROOTFS"/opt/mjpg_streamer

	cat >>"$ROOTFS"/etc/init.d/rcS <<-EOF
	
	echo "* Starting mjpg_streamer..."
	/opt/mjpg_streamer -b -i "input_uvc.so -f 15 -r 960x720" -o "output_http.so -w /opt/www -p 80"
	EOF
	# now add the load module for the camera
	sed -i '
/^# LOAD MODULES/ a\
modprobe uvcvideo >/dev/null 2>&1
' "$ROOTFS"/etc/init.d/rcS
end_package
fi

#######################################################################
## mDSNResponder
#######################################################################
if [ -d "$BUILD/mDNSResponder" ]; then
package mDNSResponder
	configure echo Done &&
	compile $MAKE os=linux CC="$GCC" SAResponder \
		CFLAGS_CROSS="-Os $TARGET_CFLAGS -I$STAGING/include" \
		LINKOPTS="-L$STAGING/lib -static" &&
	install cp build/prod/mDNSResponderPosix  "$ROOTFS/bin/"
end_package
fi

