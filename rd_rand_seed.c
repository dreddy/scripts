/* Compare the performance of RDSEED and RDRAND.
 *
 * Compute the CPU time used to fill a buffer with (pseudo) random bits 
 * using each instruction.
 *
 * Compile with: gcc -mrdrnd -mrdseed
 */
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <x86intrin.h>

#define BUFSIZE (1<<24)

int main() {

  unsigned int ok, i;
  unsigned long long *rand = malloc(BUFSIZE*sizeof(unsigned long long)), 
                     *seed = malloc(BUFSIZE*sizeof(unsigned long long)); 

  clock_t start, end, bm;

  // RDRAND (the benchmark)
  start = clock();
  for (i = 0; i < BUFSIZE; i++) {
    while (!_rdrand64_step(&rand[i]))
        ;
  }
  end = clock();
  printf("RDRAND: %li, %.2lf\n", end - start, (double)(end - start)/BUFSIZE);

  // RDSEED
  start = clock();
  for (i = 0; i < BUFSIZE; i++) {
    while (!_rdseed64_step(&seed[i]))
        ;
  }
  end = clock();
  printf("RDSEED: %li, %.2lf\n", end - start, (double)(end-start)/BUFSIZE);

  free(rand);
  free(seed);
  return 0;
}
