#!/usr/bin/env python3

import os
import sys
import struct

def usage():
    print("Usage: %s -r/-w [cpu] <msr> [value]" % sys.argv[0])
    
def read_msr(cpu=0, msr=0x10):
    fd=os.open("/dev/cpu/"+ str(cpu) + "/msr", (os.O_RDONLY))
    os.lseek(fd, msr, 0)
    value=os.read(fd, 8)
    value=struct.unpack('Q', value)[0]
    print('0x%x' % (value,))
    os.close(fd)
    return value

def write_msr(cpu, msr, value):
    print("Write %s to %s on CPU%s\n" %  (str(value),str(msr),str(cpu)))
    value=struct.pack('Q', value)
    fd=os.open("/dev/cpu/"+ str(cpu) + "/msr", (os.O_RDWR))
    os.lseek(fd, msr, 0)
    os.write(fd, value)
    os.close(fd)
    return

def main(argv=None):
    if argv is None :
        argv = sys.argv
    if len(argv) > 5 or len(argv) < 3 :
        usage()
        return -1

    if (argv[1] == '-r'):
        print('Read msr')
        if (len(argv) == 3):
            msr = int(argv[2], 16)
            cpus = int(os.sysconf('SC_NPROCESSORS_ONLN'))
            for i in range (0, cpus):
                read_msr(i, msr)
        else :
            cpu = int(argv[2], 16)
            msr = int(argv[3], 16)
            read_msr(cpu, msr)
    if (argv[1] == '-w'):
        print('Write msr')
        if(len(argv) == 4):
            msr = int(argv[2], 16)
            value = int(argv[3], 16)
            cpus = int(os.sysconf('SC_NPROCESSORS_ONLN'))
            for i in range (0, cpus):
                write_msr(i, msr, value)
        else:
            cpu = int(argv[2], 16)
            msr = int(argv[3], 16)
            value = int(argv[4], 16)
            write_msr(cpu, msr, value)

if __name__ == "__main__":
    sys.exit(main())
