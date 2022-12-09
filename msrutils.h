
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>


typedef union {
        uint64_t val64;
        uint32_t val32[2];
        uint16_t val16[4];
        uint8_t  val8[8];
} msr_val_t;


/* Caller has to deal with the fd himself */
int open_msrfd(int cpu)
{
	int msr_fd;
	char msr_fname[64];
	sprintf(msr_fname, "/dev/cpu/%d/msr", cpu);
	msr_fd = open(msr_fname, O_RDWR);
	if (msr_fd < 0) {
		perror("open: ");
		exit(-1);
	}
	return msr_fd;
}

int close_msrfd(int fd)
{
	close(fd);
}

int read_msr(int fd, uint64_t reg, uint64_t *val)
{
	assert(fd>0);
	if (pread(fd, val, sizeof(uint64_t), (off_t)reg) != sizeof(uint64_t))
		perror("rdmsr: ");
	return 0;
}

int write_msr(int fd, uint64_t reg, uint64_t val)
{
	assert(fd>0);
	if (pwrite(fd, &val, sizeof val, (off_t)reg) != sizeof val)
		perror("wrmsr: ");
	return 0;
}
