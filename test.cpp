#include <unistd.h>
#include <cstdlib>

void hot() {
  volatile long sum = 0;
  for (long i = 0; i < 300'000'000; ++i) sum += i;  // CPU hotspot
  usleep(100'000);  // Pause for sampling
}

int main() {
  int* leak = new int[1000];   // 4KB intentional leak
  (void)leak;  // Silence warning
  for (int i = 0; i < 5; ++i) {
    hot();
  }
  return 0;  // Leak not freed
}
