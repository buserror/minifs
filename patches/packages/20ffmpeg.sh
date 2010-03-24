#######################################################################
## ffmpeg
#######################################################################
PACKAGES+=" ffmpeg"

hset url ffmpeg		"http://ffmpeg.org/releases/ffmpeg-0.5.tar.bz2"
hset depends ffmpeg "busybox"

configure-ffmpeg() {
	configure ./configure \
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
