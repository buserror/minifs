#!/bin/hush
#set -x

#echo "* Trampoline starting..."
mount -t proc /proc /proc
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null

if ! mount -t jffs2 /dev/mtdblock17 /root -o ro ; then
	echo "* Cant mount boot partition, bailing"
	exec /bin/hush
fi
rootname=$(ls /root/minifs-*.img -1|tail -1)
echo "* Loading $rootname"
mkdir -p pivot
if ! mount "$rootname" /pivot/ -o ro; then
	echo "* Failed to mount $rootname, bailing"
	exec /bin/hush
fi

echo "* Bouncing"
mount -o move /root /pivot/root
touch /init # this is needed for switch_root
exec /sbin/switch_root /pivot /sbin/init
