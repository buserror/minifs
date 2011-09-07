#!/bin/bash

#
# This script replaces the nvidia binary installer. It reads the
# .manifest file describing what to install, and does it with a
# rather large awk script.
# This script generates /another/ script as output, that can
# then be evaluated
#
DESTDIR="\$DESTDIR"
export OPENGL_LIB=$DESTDIR/lib
export OPENGL_SYMLINK=$OPENGL_LIB
export LIBGL_LA=$OPENGL_LIB
export OPENGL_HEADER=$DESTDIR/include
export XMODULE_SHARED_LIB=$DESTDIR/lib/xorg/modules
export XMODULE_SYMLINK=$XMODULE_SHARED_LIB
export XMODULE_NEWSYM=$XMODULE_SHARED_LIB
export TLS_LIB=$DESTDIR/lib

export XLIB_STATIC_LIB=$DESTDIR/lib
export XLIB_SHARED_LIB=$XLIB_STATIC_LIB
export XLIB_SYMLINK=$XLIB_SHARED_LIB
export UTILITY_BINARY=$DESTDIR/bin
export UTILITY_BIN_SYMLINK=$UTILITY_BINARY
export UTILITY_LIB=$DESTDIR/lib
export UTILITY_LIB_SYMLINK=$UTILITY_LIB

export CUDA_ICD=$DESTDIR/etc/OpenCL/vendors
export CUDA_LIB=$DESTDIR/lib
export CUDA_SYMLINK=$CUDA_LIB

export VDPAU_LIB=$DESTDIR/lib
export VDPAU_SYMLINK=$VDPAU_LIB
export NVCUVID_LIB=$DESTDIR/lib
export NVCUVID_LIB_SYMLINK=$NVCUVID_LIB

echo "set -x"
cat .manifest | gawk "
function env(what, extra) {
	if (!(what in ENVIRON)) {
		print \"  #\", what, \" is not defined\"
		return \"\"
	}
	dir=ENVIRON[what] \"/\" extra;
	if (!(dir in dirmade)) {
		printf(\"mkdir -p %s\n\", dir);
		dirmade[dir] = 1
	}
	return dir
}
{
	if (header++ < 8) next;
	fil=\$1;
	perm=\$2;
	dest=\$3;

	switch (dest) {
		case /^DOC/:
		case /^MAN/:
		case /SRC$/:
		case /DESKTOP$/:
		case /INSTALLER_BINARY/:
		case /NEWSYM/: # not needed
		#	print \"# skip\", dest;
			next;
		case /COMPAT32/: 
			print \"# skip\", dest;
			next;
	}
	path=\"\"
	if (\$(NF) == \"COMPAT32\")
		next;
	for (i = 4; i < NF; i++) {
		switch (\$(i)) {
			case \"NATIVE\":
			case \"NEW\":
			case \"CLASSIC\":
			case \"/\":
				break;
			case \"COMPAT32\": 
			#	print \"# skip\", fil;
				next;
			default:
				path=path \$(i)
		}
	}
		
	switch (dest) {
		case /COMPAT32/:
			print \"# skip LOW \", fil;
			next;
		case /SYMLINK/:
			printf(\"ln -f -s %s %s%s\\n\", \$(NF), env(dest,path), fil);
			next;
		
		default:
	#		print \"# dest\", dest, \$(NF);
			dir = sprintf(\"%s%s\", env(dest, path), match(\$(NF), /^[A-Z]/) ? \"\" : \$(NF));
			if (!(dir in dirmade)) {
				printf(\"mkdir -p %s\n\", dir);
				dirmade[dir] = 1
			}
			printf(\"cp -fa %s %s\\n\", fil, dir);
			next;
	}
	print \"  # ERROR, WHATS THAT? \", dest, fil, NF
}"
