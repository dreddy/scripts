#!/bin/bash

if [ $USER != "root" ] ; then
    echo "Restarting script with sudo..."
    sudo $0 ${*}
    exit
fi

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 0 > /proc/sys/kernel/numa_balancing
x86_energy_perf_policy performance
cpupower frequency-set -g performance 1>/dev/null

#for i in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
#do
#   [ -f $i ] && echo performance > $i 1>/dev/null
#done
#
