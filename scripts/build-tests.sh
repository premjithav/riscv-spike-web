#!/usr/bin/env bash
# riscv-tests ISA suite, out-of-tree in build/tests
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$ROOT/build/tests" && cd "$ROOT/build/tests"
[ -f Makefile ] || "$TESTS_SRC/configure"
make -j"$(nproc)" isa RISCV_PREFIX="$RISCV_PREFIX" XLEN=64

# rv64ua: upstream needs -march=..._zacas_zabha (GCC 15+). Build the classic
# AMO/LR-SC tests with rv64g so atomics are still covered on GCC 14.
S="$TESTS_SRC/isa"
cd "$ROOT/build/tests/isa"
for f in "$S"/rv64ua/*.S; do
  n=$(basename "$f" .S); case $n in amocas*|*_b|*_h) continue;; esac
  [ -f "rv64ua-p-$n" ] && continue
  ${RISCV_PREFIX}gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden \
    -nostdlib -nostartfiles -I"$S/../env/p" -I"$S/macros/scalar" -T"$S/../env/p/link.ld" \
    "$f" -o "rv64ua-p-$n"
done
