#!/bin/bash

# Number of cpus default to SPR 112
if [ -z "$1" ]
then
    ncpus=`getconf _NPROCESSORS_ONLN`
else
    ncpus=$1
fi

if [ -f .config ] 
then
## Just add to the existing logfile
    for i in `seq 0 5`
    do
        make clean;
        echo `uname -a` >> ~/kernlog;
        sleep 1;
        /usr/bin/time -a -o ~/kernlog make -j $ncpus 1> /tmp/oplog 2> /tmp/errlog;
    done 

else
    echo ".config does not exist"
fi
