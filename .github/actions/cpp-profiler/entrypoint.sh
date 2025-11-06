#!/bin/bash
set -euo pipefail

# ---- Debug: local mode ----------------------------------------------------
[[ -z "${GITHUB_ACTIONS:-}" ]] && echo "Running in local mode"

# ---- Print INPUT_* (only in CI) -------------------------------------------
[[ -n "${GITHUB_ACTIONS:-}" ]] && {
  echo "::group::INPUT variables"
  env | grep '^INPUT_' | sort | while IFS='=' read -r k v; do
    c="${k#INPUT_}"; c="${c,,}"; c="${c//_/-}"
    printf "  %s = %s\n" "$c" "$v"
  done
  echo "::endgroup::"
}

# ---- Compile with forced profiler link ------------------------------------
if [[ -f "test.cpp" ]]; then
  echo "Compiling with -lprofiler (forced)..."
  g++ -g -O0 -Wl,--no-as-needed -lprofiler test.cpp -o test || { echo "::error::Compile failed"; exit 1; }
  ldd test
fi

# ---- Binaries -------------------------------------------------------------
BINARIES=("${@:-test}")
[[ ${#BINARIES[@]} -eq 0 ]] && { echo "::error::No binary specified"; exit 1; }

for bin in "${BINARIES[@]}"; do
  [[ ! -x "$bin" ]] && { echo "::error::Binary $bin missing or not executable"; continue; }

  echo "=== Profiling $bin ==="

  # Valgrind memcheck
  if [[ "${INPUT_VALGRIND_MEMCHECK:-true}" == "true" ]]; then
    # Valgrind memcheck
    valgrind --tool=memcheck \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --read-var-info=yes \
    --keep-debuginfo=yes \
    "./$bin" \
    > "${bin}_valgrind_memcheck.out" 2>&1 || true
  fi

  # Valgrind callgrind
  if [[ "${INPUT_VALGRIND_CALLGRIND:-false}" == "true" ]]; then
    valgrind --tool=callgrind "./$bin" \
             > "${bin}_valgrind_callgrind.out" 2>&1 || true
  fi

# gperftools
if [[ "${INPUT_GPERFTOOLS:-false}" == "true" ]]; then
  echo "Running gperftools (100 Hz sampling)..."
  export CPUPROFILE_FREQUENCY=100
  export CPUPROFILE="${bin}_profile.out"
  "./$bin" || true

  if [[ -f "${bin}_profile.out" ]]; then
    pprof --text "/workspace/$bin" "${bin}_profile.out" > "${bin}_pprof.out" 2>&1 || true
    pprof --png  "/workspace/$bin" "${bin}_profile.out" > "${bin}_flamegraph.png" 2>&1 || true
  else
    echo "::warning::No profile data (check -lprofiler and runtime)"
  fi
fi

  # Parse with absolute path
  /app/venv/bin/python /app/parse_profile.py \
    "${bin}_valgrind_memcheck.out" \
    "${bin}_valgrind_callgrind.out" \
    "${bin}_pprof.out" \
    "$bin"
done

# ---- Artifacts ------------------------------------------------------------
ARTIFACT_DIR="/tmp/artifacts"
mkdir -p "$ARTIFACT_DIR"
cp -f *.out "$ARTIFACT_DIR"/ 2>/dev/null || true
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "artifacts=$ARTIFACT_DIR" >> "$GITHUB_OUTPUT"
else
  echo "Artifacts in $ARTIFACT_DIR:"
  ls -la "$ARTIFACT_DIR"
fi