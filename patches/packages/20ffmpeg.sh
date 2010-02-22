#######################################################################
## ffmpeg
#######################################################################
PACKAGES="$PACKAGES ffmpeg"

configure-ffmpeg() {
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
		 --disable-mmx --disable-mmx2  --disable-sse --disable-ssse3
}
