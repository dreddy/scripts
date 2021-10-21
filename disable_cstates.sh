#!/bin/bash

# Use cpupower-idle-set if available

count=`getconf _NPROCESSORS_ONLN`
max_cstates=`ls /sys/devices/system/cpu/cpu0/cpuidle | wc -l`
for i in `seq 0 $((count-1))`; do
   for j in `seq 1 $((max_cstates -1))`; do
     echo "1" >  /sys/devices/system/cpu/cpu$i/cpuidle/state$j/disable
     grep -H . /sys/devices/system/cpu/cpu$i/cpuidle/state$j/name
     grep -H . /sys/devices/system/cpu/cpu$i/cpuidle/state$j/disable
   done
done

