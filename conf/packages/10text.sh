
# 110906 No changes http://expat.sourceforge.net/
PACKAGES+=" libexpat"
hset libexpat url "http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz"

# 110906 Updated 6.2 http://cnswww.cns.cwru.edu/php/chet/readline/rltop.html
PACKAGES+=" libreadline"
hset libreadline url "ftp://ftp.gnu.org/gnu/readline/readline-6.2.tar.gz"

# 110906 Updated 5.9 http://www.gnu.org/software/ncurses/
# 180203 Updated 6.1 http://www.gnu.org/software/ncurses/
PACKAGES+=" libncurses"
hset libncurses url "http://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.1.tar.gz"
hset libncurses configscript "ncurses6-config"

configure-libncurses() {
    #provide some sort of compatibility for people using ncurses5
	ln -sf ncurses6-config "$STAGING_TOOLS"/bin/ncurses5-config
    # CPPFLAGS is needed because of debian version of mawk, somehow
	configure-generic CPPFLAGS="-P" \
		--without-ada --without-progs \
		--without-tests --enable-pc-files
}
deploy-libncurses() {
	mkdir -p "$ROOTFS"/usr/share/
	deploy cp -ra "$STAGING_USR"/share/terminfo "$ROOTFS"/usr/share/
}

PACKAGES+=" libtermbox"
hset libtermbox url "https://github.com/nsf/termbox/archive/v1.1.2.tar.gz"
hset libtermbox dir "libtermbox/src"

patch-libtermbox() {
    echo patching $PACKAGE in $(pwd)
    echo PACKAGE dir is $(get_package_dir $PACKAGE)
    cp "$PATCHES/$PACKAGE-make/"* src/
}

PACKAGES+=" libnewt"
hset libnewt url "http://ftp.de.debian.org/debian/pool/main/n/newt/newt_0.52.14.orig.tar.gz"
hset libnewt depends "slang libpopt"

configure-libnewt() {
	configure-generic --disable-nls --without-python --without-tcl
}

# this is only needed for uclibc! otherwise eglibc has one already
PACKAGES+=" libiconv"
if [ "$CONFIG_UCLIBC" != "" ]; then
	# echo UCLIBC build - add libiconv
	hset libiconv url "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"
fi

configure-libiconv() {
	configure-generic \
		--disable-rpath \
		--disable-nls
}

# 110906 Updated 2.7.8 ftp://xmlsoft.org/libxml2/
PACKAGES+=" libxml2"
hset libxml2 url "ftp://xmlsoft.org/libxml2/libxml2-2.7.8.tar.gz"
hset libxml2 configscript "xml2-config"

configure-libxml2() {
	configure-generic \
		--without-python
}

install-libxml2() {
	install-generic
	# fix that script
	if [ -f "$STAGING_USR"/lib/xml2Conf.sh ]; then
		sed -i \
			-e "s|I/usr|I$STAGING_USR|g" \
			-e "s|L/usr|L$STAGING_USR|g" \
				"$STAGING_USR"/lib/xml2Conf.sh
	fi
}

# 110906 No Changes
if [ "$CONFIG_UCLIBC" != "" ]; then
	PACKAGES+=" libgettext"
fi
#hset libgettext url "http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.1.1.tar.gz"
#hset libgettext url "http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.6.tar.xz"
hset libgettext url "http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.8.tar.xz"
hset libgettext depends "libxml2 libiconv"

configure-libgettext() {
	#rm -f configure ;
	sed -i -e 's/gettext-tools$//' Makefile.am
	aclocal
	configure-generic \
		--without-lispdir \
                 --disable-csharp \
                 --disable-libasprintf \
                 --disable-java \
                 --disable-native-java \
                 --disable-openmp \
                 --with-included-glib \
                 --without-emacs \
                 --with-libncurses-prefix="$STAGING_USR" \
                 --with-libxml2-prefix="$STAGING_USR"
#	CFLAGS="$TARGET_CFLAGS"
}

