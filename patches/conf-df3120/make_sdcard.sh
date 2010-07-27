#!/bin/bash
exit

dd if=/opt/minifs/build-df3120/minifs-full-ext.img of=/dev/sdg1 bs=4M

ifconfig usb0 172.16.61.2 netmask 255.255.255.0 up

cat /proc/meminfo
