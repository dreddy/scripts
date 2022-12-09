#!/bin/bash


start=$2
end=$2

if [ $# = 3 ]
then
	end=$3
fi

if [ $1 == "on" ]
then
	echo "Setting $start,$end CPUs online"
	online=1
elif [ $1 == "off" ]
then
	online=0
	echo "Setting $start,$end CPUs offline"
fi

for i in `seq $start $end`
do
  echo -n $online | sudo tee /sys/devices/system/cpu/cpu${i}/online
done
