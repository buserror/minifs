#!/bin/hush
#set -x

echo "* Trampoline starting..."
mount -t proc /proc /proc
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null

/bin/waitfor_uevent 2000 ACTION=add DEVTYPE=partition

if ! /bin/fat_find -e 'minifs-*.img' -l /tmp/boot >/dev/null ; then
	echo "* Cant find a root partition, bad idea "
	exec /bin/hush
fi

if ! mount /tmp/boot /root -o ro ; then
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
