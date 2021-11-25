#!/bin/bash

/usr/local/qemu.git/bin/qemu-system-x86_64 \
		-machine q35,accel=tcg,kernel-irqchip=split \
		-cpu max \
		-m 32768 \
		-smp cores=4 \
		-drive file=/srv/data/OVMF_CODE.fd,if=pflash,format=raw,readonly=on \
		-drive file=/srv/data/OVMF_VARS.fd,if=pflash,format=raw \
		-vga none \
		-nographic \
		-device e1000,netdev=network0,mac=52:54:00:12:34:56 \
		-netdev user,id=network0 \
		-device virtio-blk-pci,drive=mydrive \
		-drive id=mydrive,file=/srv/data/debian-testing.qcow2,cache=writeback,l2-cache-size=39321600,if=none  \
		-curses
