
#define _GNU_SOURCE

#include <pthread.h>
#include <sched.h>

#include <unistd.h>

#include <assert.h>

#include <stdio.h>
#include <stdint.h>
#include <immintrin.h>


float __attribute__((aligned(0x20)))arr1[8] = 
{ 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5 };
float __attribute__((aligned(0x20)))arr2[8] = 
{ 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5 };
float __attribute__((aligned(0x20)))arr3[8];

float sample_avx_mult(void)
{
	__m256 ymm0, ymm1, ymm2, ymm3, ymm4, ymm5, ymm6, ymm7,
		ymm8, ymm9, ymm10, ymm11, ymm12, ymm13, ymm14, ymm15;
	int i;
	float rv;

	 ymm0 = _mm256_load_ps(arr1);
	 ymm1 = _mm256_load_ps(arr2);
	 ymm2 = _mm256_load_ps(arr1);
	 ymm3 = _mm256_load_ps(arr2);
	 ymm4 = _mm256_load_ps(arr1);
	 ymm5 = _mm256_load_ps(arr2);
	 ymm6 = _mm256_load_ps(arr1);
	 ymm7 = _mm256_load_ps(arr2);



	 ymm8 = _mm256_add_ps(ymm0, ymm1);
	 ymm9 = _mm256_mul_ps(ymm2, ymm3);

	 ymm10 = _mm256_add_ps(ymm4, ymm5);
	 ymm11 = _mm256_mul_ps(ymm6, ymm7);



	 ymm12 = _mm256_add_ps(ymm8, ymm9);
	 ymm13 = _mm256_mul_ps(ymm10, ymm11);

	 ymm14 = _mm256_add_ps(ymm12, ymm13);
	 	 
	_mm256_store_ps(arr3, ymm15);
	for(i=0; i<8; i++)
		rv += arr3[i];

	return rv;
}

void * avx2_thread(void * attr)
{
	float x=0.0;

	while(1) {
		x+=sample_avx_mult();
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
	
	if (!(lo & 0x4))
		printf("ymm state not enabled by xsave\n");

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
		rv = pthread_create(&tid[itr], &attr, avx2_thread, NULL);
		assert(rv==0);
	}

	for (itr=0; itr<ncopies; itr++)
		pthread_join(tid[itr], NULL);

	pthread_attr_destroy(&attr);
	pthread_exit(NULL);
	return 0;
}
	
