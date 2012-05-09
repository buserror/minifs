minifs -- Compact Linux Distro Generator
=============

*minifs* was made to create monolitic linux firmwares, because in a lot of
cases you don't really need "packages" and incremental updates.

*minifs* download all components tarball, will compile a toolchain for 
your target platform, a C library,
a linux kernel, busybox, and every package you might want, then create 
a filesystem in either ext, jffs2, or even an initramfs compacted 
with a kernel.

*minifs* makes a root filesystem by the traditional way of using a
"staging" directory to install everything, then selectively copying
items that are wanted, /then/ using a new tool called the *cross linker*
to check what executable really use as libraries, and jetinson everything
else.

*minifs* has been in almost permanent development for the last few years,
and has been used in multiple projects. It runs on ARM 
([Picfure Frames](https://sites.google.com/site/repurposelinux/df3120),
[mini2440](http://www.andahammer.com/mini244-2/), beagleboard
etc) and on x86 (from the gumstick sized [bifferboard](http://bifferos.co.uk/)
to O2 Joggler, to full fat amd64.

*minifs* is written in bash. It's pretty easy to extend, and most of the
time adding a package is adding 3 lines to the config file. It has inter-package
dependencies and a few niceties, but it's really made to stay simple and
easy to hack and maintain.