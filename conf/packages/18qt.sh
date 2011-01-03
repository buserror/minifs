
PACKAGES+=" qt"
V="4.7.2"
hset qt version $V
hset qt url "http://get.qt.nokia.com/qt/source/qt-everywhere-opensource-src-$V.tar.gz"
hset qt depends "zlib libjpeg libpng libfreetype libts libfontconfig"

configure-qt() {
	(
	unset CC CXX CCFLAGS CXXFLAGS
	configure ./configure \
		-opensource \
		-prefix "$STAGING_USR" \
		-L "$STAGING_USR"/lib \
		-I "$STAGING_USR"/include \
		-release -shared \
		-fast \
		-pch \
		-no-qt3support \
		-qt-sql-sqlite \
		-no-libtiff -no-libmng \
		-no-openssl \
		-nomake examples -nomake demos -nomake tools\
		-optimized-qmake \
		-no-phonon \
		-no-nis \
		-no-opengl \
		-no-cups \
		-no-xcursor -no-xfixes -no-xrandr -no-xrender -no-xkb -no-sm\
		-no-xinerama -no-xshape \
		-no-separate-debug-info \
		-xplatform qws/linux-arm-g++ \
		-embedded arm \
		-depths 16 \
		-no-qvfb \
		-qt-gfx-linuxfb \
		-no-gfx-qvfb -no-kbd-qvfb -no-mouse-qvfb\
		-confirm-license \
		-qt-kbd-linuxinput \
		-qt-mouse-linuxinput \
		-qt-mouse-tslib \
		-fontconfig
	) || return 1
}
