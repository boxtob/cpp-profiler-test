#include <unistd.h>
#include <cstdlib>
#include <iostream>
#include <cstring>

void hot(bool verbose) {
  if (verbose) std::cout << "  [hot] Starting CPU loop...\n";
  volatile long sum = 0;
  for (long i = 0; i < 2'000'000'000; ++i) sum += i;  // CPU hotspot
  usleep(200000);  // Pause for sampling
  if (verbose) std::cout << "  [hot] Loop done.\n";
}

int main(int argc, char* argv[]) {
  bool verbose = false;
  for (int i = 1; i < argc; ++i) {
    if (std::strcmp(argv[i], "--verbose") == 0) {
      verbose = true;
      std::cout << "[main] Verbose mode enabled\n";
    }
  }

  std::cout << "[main] Allocating 4KB leak...\n";
  int* leak = new int[1000];   // 4KB intentional leak
  (void)leak;  // Silence warning

  for (int i = 0; i < 5; ++i) {
    if (verbose) std::cout << "[main] Running hot() iteration " << (i+1) << "/5\n";
    hot(verbose);
  }

  std::cout << "[main] Done. Leak not freed.\n";
  return 0;
}
