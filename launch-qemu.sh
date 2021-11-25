#!/bin/bash

qemu-system-x86_64 -M q35,accel=kvm,kernel-irqchip=split \
		-cpu host \
		-m 32768 \
		-smp cores=8 \
		-drive file=/srv/data/OVMF_CODE.fd,if=pflash,format=raw,readonly=on \
		-drive file=/srv/data/OVMF_VARS.fd,if=pflash,format=raw \
		-vga none \
		-nographic \
		-net none \
		-device vfio-pci,host=3d:02.0 \
		-drive id=mydrive,file=/srv/data/fbsd12.qcow2,cache=writeback,l2-cache-size=39321600,if=none  \
		-device virtio-blk-pci,drive=mydrive \
		-curses
