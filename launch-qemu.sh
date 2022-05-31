#!/bin/bash

## storage: drive and device are interlinked with the id field
## networking: netdev and device are interlinked with the id field
## Else configure vfio device and directly assign the device to guest OS
EXEC=qemu-system-x86_64
ARGS="-M q35,accel=kvm,kernel-irqchip=split \
	-cpu Cascadelake-Server-v4 -smp cores=4 \
	-m 16384 \
	-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
	-drive if=pflash,format=raw,file=/srv/data/VMs/OVMF_VARS.fd \
	-netdev user,id=network0 \
	-device e1000,netdev=network0,mac=52:54:00:12:34:56 \
	-drive id=mydrive,file=/srv/data/VMs/debian-testing.qcow2,cache=writeback,l2-cache-size=39321600,if=none  \
	-device virtio-blk-pci,drive=mydrive,id=virtblk0,num-queues=4 \
	-vga none -nographic \
	-monitor unix:qemu-monitor-socket,server,nowait \
	-serial mon:stdio "

if [ $1 == "listen" ]
then
	ARGS="${ARGS} -incoming tcp:0:4444"
fi

${EXEC} ${ARGS}
#	-net none \
#	-device vfio-pci,host=3d:06.0 \
#	-display curses
