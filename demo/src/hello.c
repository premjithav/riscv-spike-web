// Bare-metal hello for Spike: printf goes through HTIF (tohost/fromhost)
#include <stdint.h>
#include "util.h"
int printf(const char* fmt, ...);

static uint64_t read_csr_misa(void){ uint64_t v; asm volatile("csrr %0, misa":"=r"(v)); return v; }

static unsigned fib(unsigned n){ return n < 2 ? n : fib(n-1) + fib(n-2); }

int main(int argc, char** argv)
{
  uint64_t misa = read_csr_misa();
  printf("Hello from RISC-V, running on Spike compiled to WebAssembly!\n\n");
  printf("misa = 0x%lx  ->  RV%d", misa, (int)(16 << (misa >> 62)));
  for (int i = 0; i < 26; i++) if (misa & (1UL << i)) printf("%c", 'A' + i);
  printf("\n\nfib(0..20): ");
  for (unsigned i = 0; i <= 20; i++) printf("%u ", fib(i));
  printf("\n");
  return 0;
}
