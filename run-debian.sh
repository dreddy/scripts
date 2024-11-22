#!/bin/sh

## Use teh following to create a chroot tarball
##
#sudo debootstrap --arch=arm64  testing `pwd`/debian http://deb.debian.org/debian
#sudo tar -czplf debian.tar.gz debian
#adb root
#adb push debian.tar.gz /data/user/.
#adb shell tar zxpf /data/user/debian.tar.gz -C /data/user
#adb shell -t /data/user/run-debian
##
##
##

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\$PATH
export HOME=/root
mount -o bind /dev /data/user/debian/dev
mount -o bind /sys /data/user/debian/sys
mount -o bind /proc /data/user/debian/proc
mount -o bind /dev/pts /data/user/debian/dev/pts
chroot /data/user/debian /bin/bash -l
umount /data/user/debian/dev/pts
umount /data/user/debian/proc
umount /data/user/debian/sys
umount /data/user/debian/dev

