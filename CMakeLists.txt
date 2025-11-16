cmake_minimum_required(VERSION 3.14)
project(HotspotLeak LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Enable warnings and debugging
add_compile_options(-Wall -Wextra -g -O0)

# Add executable
add_executable(hotspot_leak src/main.cpp)

# ---- Link with -lprofiler --------------------------------------------
# Find the library (optional but recommended)
find_library(PROFILER_LIB profiler
    HINTS
        /usr/lib
        /usr/lib/x86_64-linux-gnu
        /usr/local/lib
    REQUIRED)

if (NOT PROFILER_LIB)
    message(FATAL_ERROR "libprofiler not found – install libgoogle-perftools-dev")
endif()

# Force-link libfoo even if no symbols are used
target_link_options(hotspot_leak PRIVATE "-Wl,--no-as-needed")

# Link it
target_link_libraries(hotspot_leak PRIVATE ${PROFILER_LIB})

# Link required libraries (pthread for usleep, though usually not needed on Linux)
target_link_libraries(hotspot_leak PRIVATE pthread)

install(TARGETS hotspot_leak RUNTIME DESTINATION bin)