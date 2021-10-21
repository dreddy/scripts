#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "ERROR: $1 is the device name from /proc/interrupts"
  exit 1
fi

cat /proc/interrupts  | grep $1 |  awk '{printf "%s\t%s\t%s\t\n", $1, $(NF-1), $(NF)}'
