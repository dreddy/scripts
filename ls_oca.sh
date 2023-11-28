#!/bin/bash

## List the On-chip accelerators in SPR

IFS=$'\n'

SPR_DSA=0x0b25
SPR_IAA=0x0cfe
SPR_QAT_PF1=0x4940
SPR_QAT_VF1=0x4941
SPR_QAT_PF2=0x4942
SPR_QAT_VF2=0x4943
SPR_DLB_PF=0x2710
SPR_DLB_VF=0x2711
QAT_C6X=0x37c8
for i in /sys/bus/pci/devices/*
do
    vendor=$(<${i}/vendor)
    device=$(<${i}/device)

    case $device in
        ${QAT_C6X})
            echo "QAT_C6X:    $vendor : $device"
            ;;
        ${SPR_DSA})
            echo "SPR_DSA:    $vendor : $device"
            ;;
        ${SPR_IAA})
            echo "SPR_IAA:    $vendor : $device"
            ;;
        ${SPR_QAT_PF1})
            echo "SPR_QAT_PF: $vendor : $device"
            ;;
        ${SPR_QAT_PF2})
            echo "SPR_QAT_PF: $vendor : $device"
            ;;
        ${SPR_DLB_PF})
            echo "SPR_DLB_PF: $vendor : $device"
            ;;
        ${SPR_QAT_VF1})
            echo "SPR_QAT_VF: $vendor : $device"
            ;;
        ${SPR_QAT_VF2})
            echo "SPR_QAT_VF: $vendor : $device"
            ;;
        ${SPR_DLB_VF})
            echo "SPR_DLB_VF: $vendor : $device"
            ;;
    esac
done
