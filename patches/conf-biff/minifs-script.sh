TARGET_ARCH=i386
TARGET_FULL_ARCH=$TARGET_ARCH-minifs-linux-uclibc
TARGET_KERNEL_NAME=bzImage
TARGET_CFLAGS="-Os"

board_prepare()
{
if [ ! -f "mjpg-streamer.tar.bz2" ]; then
        echo "####  Downloading SVN and creating tarball of mjpg-streamer"
        svn co "https://mjpg-streamer.svn.sourceforge.net/svnroot/mjpg-streamer/mjpg-streamer" &&
        tar jcf mjpg-streamer.tar.bz2 mjpg-streamer &&
        rm -rf mjpg-streamer
fi
url[${#url[@]}]="mjpg-streamer.tar.bz2"

	# webcam support
url[${#url[@]}]="http://www.ijg.org/files/jpegsrc.v7.tar.gz" 
url[${#url[@]}]="http://matt.ucc.asn.au/dropbear/releases/dropbear-0.52.tar.bz2" 
url[${#url[@]}]="mjpg-streamer.tar.bz2"
}

board_finish() {
	true
}

board_compile() {
	true
}
