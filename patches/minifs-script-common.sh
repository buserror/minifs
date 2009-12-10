
#######################################################################
## screen
#######################################################################

if [ -d "$BUILD/screen" ]; then
echo "#### building screen"
pushd "$BUILD/screen"
	./configure --enable-static --disable-shared \
		--prefix="$ROOTFS" \
		--target=$TARGET_FULL_ARCH \
		--host=i386-unknown-linux-uclibc \
		--build=i386 \
		PATH="$STAGING/bin:$PATH" &&
	$MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	$MAKE install PATH="$STAGING/bin:$PATH"
popd
fi

#######################################################################
## i2c-tools
#######################################################################
if [ -d "$BUILD/i2c" ]; then
echo "#### building i2c"
pushd "$BUILD/i2c"
	$MAKE CC="$GCC" CFLAGS="-Os $TARGET_CFLAGS" LDFLAGS="-static" &&
	cp ./tools/i2c{detect,dump,get,set} "$ROOTFS/bin/"
popd
fi

#######################################################################
## libusb
#######################################################################
if [ -d "$BUILD/libusb" ]; then
echo "#### building libusb"
pushd "$BUILD/libusb"
	./configure --enable-static --disable-shared \
		--prefix="$STAGING" \
		--target=$TARGET_FULL_ARCH \
		--host=i386-unknown-linux-uclibc 
		--build=i386 \
		PATH="$STAGING/bin:$PATH" CFLAGS="$TARGET_CFLAGS" &&
	$MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	$MAKE install PATH="$STAGING/bin:$PATH"
#	cp "$STAGING/include/libusb*/libusb.h" "$STAGING"/include/usb.h
popd
fi

#######################################################################
## libftdi
#######################################################################
if [ -d "$BUILD/libftdi" ]; then
echo "#### building libftdi"
pushd "$BUILD/libftdi"
	CPPFLAGS="-I$STAGING/include"  \
	./configure --enable-static --disable-shared \
		--prefix="$STAGING" \
		--target=$TARGET_FULL_ARCH \
		--host=i386-unknown-linux-uclibc \
		--build=i386 \
		--disable-libftdipp --with-async-mode \
		PATH="$STAGING/bin:$PATH" &&
	$MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	$MAKE install PATH="$STAGING/bin:$PATH"
popd
fi

#######################################################################
## zlib and dropbear
#######################################################################

if [ -d "$BUILD/zlib" ]; then
echo "#### building zlib"
pushd "$BUILD/zlib"
	./configure \
		--prefix="$STAGING"  &&
	$MAKE -j8 PATH="$STAGING/bin:$PATH" \
		CC="$GCC" && 
	$MAKE install PATH="$STAGING/bin:$PATH" \
		CC="$GCC"
popd
fi

if [ -d "$BUILD/dropbear" ]; then
echo "#### building dropbear"
pushd "$BUILD/dropbear"
	./configure --enable-static --disable-shared \
		--prefix="$ROOTFS" \
		--target=$TARGET_FULL_ARCH \
		--host=i386-unknown-linux-uclibc \
		--build=i386 \
		--with-zlib="$STAGING" \
		PATH="$STAGING/bin:$PATH" \
		CFLAGS="-static -Os ${TARGET_CFLAGS}" \
		LDFLAGS="-static" &&
	$MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	$MAKE install PATH="$STAGING/bin:$PATH"

	mkdir -p "$ROOTFS/etc/dropbear"
	if [ $TARGET_ARCH = "i386" ]; then	
		if [ ! -f "$CONF"/dropbear_dss_host_key ]; then
			echo "#### generating new dropbear keys"
			"$ROOTFS"/bin/dropbearkey -t dss -f "$CONF"/dropbear_dss_host_key
			"$ROOTFS"/bin/dropbearkey -t rsa -f "$CONF"/dropbear_rsa_host_key
		fi
	fi
	cp "$CONF"/dropbear_*_host_key "$ROOTFS"/etc/dropbear/
popd
fi

#######################################################################
## Jpeg
#######################################################################

if [ -d "$BUILD/jpegsrc" ]; then
echo "#### building libjpeg"
pushd "$BUILD/jpegsrc"
	./configure --enable-static --disable-shared \
		--prefix="$STAGING" \
		--target=$TARGET_FULL_ARCH \
		--host=i386-unknown-linux-uclibc \
		--build=i386 \
		PATH="$STAGING/bin:$PATH" &&
	$MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	$MAKE install PATH="$STAGING/bin:$PATH"
popd
fi

if [ -d "$BUILD/ffmpeg" ]; then
echo "#### building ffmpeg"
pushd "$BUILD/ffmpeg"
	PATH="$STAGING/bin:$PATH" \
	./configure --enable-static --disable-shared \
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
		 &&
	$MAKE -j8 PATH="$STAGING/bin:$PATH" && 
	$MAKE install PATH="$STAGING/bin:$PATH"
	
popd
fi

if [ -d "$BUILD/mjpg" ]; then
echo "#### Building mjpg-streamer"
mkdir -p "$ROOTFS"/opt/
pushd "$BUILD/mjpg"
	$MAKE CC="$GCC" \
		EXTRA_LDFLAGS="-L $STAGING/lib" \
		EXTRA_CFLAGS="-Os -I$STAGING/include" \
		STATIC=1 &&
	cp -ra mjpg_streamer www "$ROOTFS"/opt/ &&
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
popd
fi

