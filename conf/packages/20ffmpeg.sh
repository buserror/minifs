#######################################################################
## ffmpeg
#######################################################################
PACKAGES+=" ffmpeg"

V="0.5"
hset ffmpeg version $V
hset ffmpeg url "http://ffmpeg.org/releases/ffmpeg-$V.tar.bz2"
hset ffmpeg depends "busybox"

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
