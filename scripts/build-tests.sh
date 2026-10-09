#!/usr/bin/env bash
# riscv-tests ISA suite, out-of-tree in build/tests
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$ROOT/build/tests" && cd "$ROOT/build/tests"
[ -f Makefile ] || "$TESTS_SRC/configure"
make -j"$(nproc)" isa RISCV_PREFIX="$RISCV_PREFIX" XLEN=64
