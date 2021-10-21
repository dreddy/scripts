

#define _GNU_SOURCE

#include <pthread.h>
#include <sched.h>

#include <unistd.h>

#include <assert.h>

#include <stdio.h>
#include <stdint.h>
#include <immintrin.h>


float __attribute__((aligned(0x40)))arr1[16] = 
  { 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5 };
float __attribute__((aligned(0x40)))arr2[16] = 
  { 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5 };
float __attribute__((aligned(0x40)))arr3[16];

float sample_avx_mult(void)
{
        __m512 zmm[32];
        int i;
        float rv;

        /* Load the regs */
        for (i=0; i< 16; i++)
                (i%2) ? (zmm[i] = _mm512_load_ps(arr1)):(zmm[i] = _mm512_load_ps(arr2));

        /* Leaf */
        for (i=0; i<8; i++)
                zmm[i+16] = _mm512_mul_ps(zmm[2*i+0], zmm[2*i+1]);

        /* Level 1 */
        for (i=0; i<4; i++)
                zmm[i+24] = _mm512_add_ps(zmm[2*i+16], zmm[2*i+17]);

        /* Level 2 */
        for(i=0; i<2; i++)
                zmm[i+28] = _mm512_mul_ps(zmm[2*i+24], zmm[2*i+25]);

        /* Level 3 */
        zmm[30] = _mm512_add_ps(zmm[28], zmm[29]);

        _mm512_store_ps(arr3, zmm[30]);

        for(i=0; i<16; i++)
                rv += arr3[i];

        return rv;
        
}

void* avx3_thread(void* attr)
{
        
        float x=0.0;

        while(1) {
                x+=sample_avx_mult();
                /* fprintf(stdout, "%5.3f\n", x); */
                x+=sample_avx_mult();
                x+=sample_avx_mult();
                x+=sample_avx_mult();
                x+=sample_avx_mult();
                x+=sample_avx_mult();
        }
}


int main( int argc, char *argv[])
{
        uint64_t xcr=0;
        uint32_t lo=0, hi=0;
        int ncopies=1;
        long ncpus = sysconf(_SC_NPROCESSORS_ONLN);
        
        if (argc == 2)
                ncopies= strtoul(argv[1], NULL, 10);


        asm ( "xgetbv\t\n"
              :"=a"(lo), "=d"(hi)
              : "c"(xcr)
                );

        /* Checking only avx-512 */
        if (!(lo & 0xE0)) /* Opmask, ZMM_u, ZMM_16-31*/
                printf("zmm state not enabled by xsave\n");
        

        if (ncopies > ncpus)
                ncopies = ncpus;

        pthread_t *tid = malloc (sizeof (pthread_t) * ncopies);
        int itr, rv;
        pthread_attr_t attr;
        cpu_set_t cpuset;

        for (itr=0; itr<ncopies; itr++) {
                CPU_ZERO(&cpuset);
                CPU_SET(itr, &cpuset);
                pthread_attr_init(&attr);
                pthread_attr_setaffinity_np(&attr, sizeof (cpuset), &cpuset);
                rv = pthread_create(&tid[itr], &attr, avx3_thread, NULL);
                assert(rv==0);
        }

        for (itr=0; itr<ncopies; itr++)
                pthread_join(tid[itr], NULL);
        
        pthread_attr_destroy(&attr);
        pthread_exit(NULL);
        return 0;
}
