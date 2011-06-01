

PACKAGES+=" opencv"
hset opencv url "http://downloads.sourceforge.net/project/opencvlibrary/opencv-unix/2.2/OpenCV-2.2.0.tar.bz2"

hostcheck-opencv() {
	hostcheck_commands cmake
}

setup-opencv() {
	mkdir -p build
	cd build
}

configure-opencv-local() {
#	set -x
	cat <<END >cmake-toolchain.conf
INCLUDE(CMakeForceCompiler)
SET(CMAKE_SYSTEM_NAME Linux)

CMAKE_FORCE_C_COMPILER($CC GNU)
CMAKE_FORCE_CXX_COMPILER($CXX GNU)
SET(CMAKE_AR $TOOLCHAIN/$TARGET_FULL_ARCH/bin/$TARGET_FULL_ARCH-ar)
SET(CMAKE_LINKER $TOOLCHAIN/$TARGET_FULL_ARCH/bin/$TARGET_FULL_ARCH-ld)

SET(CMAKE_INSTALL_PREFIX $STAGING_USR)

# where is the target environment 
SET(CMAKE_FIND_ROOT_PATH  $STAGING_USR)

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

SET(BUILD_TESTS OFF)

SET(ENABLE_SSE3 ON)
SET(ENABLE_SSSE3 ON)

SET(PYTHON_LIBRARY PYTHON_LIBRARY-NOTFOUND)
END
	cmake -DCMAKE_TOOLCHAIN_FILE=cmake-toolchain.conf ..
}

configure-opencv() {
	configure configure-opencv-local
}

compile-opencv() {
	compile-generic VERBOSE=1
}


PACKAGES+=" libclutter"
hset libclutter url "http://source.clutter-project.org/sources/clutter/1.6/clutter-1.6.8.tar.bz2"
hset libclutter depends "libglibjson"
