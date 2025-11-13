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

# Link required libraries (pthread for usleep, though usually not needed on Linux)
target_link_libraries(hotspot_leak PRIVATE pthread)