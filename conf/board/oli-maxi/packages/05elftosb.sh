
PACKAGES+=" elftosb"
hset url elftosb "http://repository.timesys.com/buildsources/e/elftosb/elftosb-10.12.01/elftosb-10.12.01.tar.gz"

compile-elftosb() {
	make CC=gcc
}
