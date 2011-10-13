
PACKAGES+=" mupdf"
hset mupdf url "git!git://git.ghostscript.com/mupdf.git#mupdf-git.tar.bz2"
hset mupdf depends "libfreetype libjpeg libjbig2dec libopenjpeg"

configure-mupdf-local() {
	sed -i \
		-e 's|$(PDF_APPS) $(XPS_APPS) $(MUPDF)||' \
		-e 's|/usr/local|$(DESTDIR)|' \
		-e 's|debug|release|' \
		Makefile
	configure-generic-local
}
configure-mupdf() {
	configure configure-mupdf-local
}
