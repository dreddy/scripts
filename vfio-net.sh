#!/bin/bash


if [ $USER != "root" ] ; then
    echo "Restarting script with sudo..."
    sudo $0 ${*}
    exit
fi

modprobe vfio-pci

setup_vfio () {
   cd /sys/bus/pci/devices/${1}
   driver=$(basename $(readlink driver))
   if [ "${driver}" != "i40e" ]; then
     echo ${1} | tee driver/unbind
     echo ${1} | tee /sys/bus/pci/drivers/i40e/bind
   fi
   ifname=$(basename net/*)
   echo 0 | tee sriov_numvfs > /dev/null
   echo 1 | tee sriov_numvfs > /dev/null
   ip link set dev ${ifname} vf 0 mac ${2}
   ip link show dev ${ifname}
   vf=$(basename $(readlink virtfn0))
   echo ${vf} | tee virtfn0/driver/unbind
   echo vfio-pci | tee virtfn0/driver_override
   echo ${vf} | sudo tee /sys/bus/pci/drivers/vfio-pci/bind
   echo  | tee virtfn0/driver_override
 }

setup_novfio () {
   cd /sys/bus/pci/devices/${1}
   driver=$(basename $(readlink driver))
   if [ "${driver}" != "i40e" ]; then
     echo ${1} | tee driver/unbind
     echo ${1} | tee /sys/bus/pci/drivers/i40e/bind
   fi
   ifname=$(basename net/*)
   echo 0 | tee sriov_numvfs > /dev/null
   echo 1 | tee sriov_numvfs > /dev/null
   ip link show dev ${ifname}
   ip link set dev ${ifname} vf 0 mac ${2}
   vf=$(basename $(readlink virtfn0))
 }

# Setup one VF on PF 0000:3d:00.0
addr1=`printf "a4:bf:01:%02X:%02X:%02X" $[RANDOM%256] $[RANDOM%256] $[RANDOM%256]`
setup_novfio 0000:3d:00.0 $addr1

# Setup one VF on PF 0000:3d:00.1
#addr2=`printf "a4:bf:01:%02X:%02X:%02X" $[RANDOM%256] $[RANDOM%256] $[RANDOM%256]`
#setup_novfio 0000:3d:00.1 $addr2
