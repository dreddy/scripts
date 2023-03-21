
#define _GNU_SOURCE
#include <sched.h>

#include <pthread.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

void* loop (void* arg)
{
	while(1)
	;
}

int main(int ac, char *av[])
{
        long ncpus;
        pthread_t *tid = malloc (sizeof (pthread_t) * ncpus);
        int i, rv;
        pthread_attr_t attr;
        cpu_set_t cpuset;

        ncpus = (ac==2) ? strtoul(av[1], NULL, 10): sysconf(_SC_NPROCESSORS_ONLN);
        for (i=0; i<ncpus; i++) {
                CPU_ZERO(&cpuset);
                CPU_SET(i, &cpuset);
                pthread_attr_init(&attr);
                pthread_attr_setaffinity_np(&attr, sizeof (cpuset), &cpuset);
                rv = pthread_create(&tid[i], &attr, loop, NULL);
		if (rv < 0) {
                        printf("pthread_create failed\n");
                        exit(-1);
		}
        }

        for (i=0; i<ncpus; i++)
                pthread_join(tid[i], NULL);

        pthread_attr_destroy(&attr);
        pthread_exit(NULL);
        return 0;
}
