#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# riscv-tests ISA suite + benchmarks (out of tree; nothing in third_party/ changes).
set -euo pipefail
source "$(dirname "$0")/env.sh"
S="$TESTS_SRC/isa"
mkdir -p "$ROOT/build/tests" && cd "$ROOT/build/tests"
[ -f Makefile ] || "$TESTS_SRC/configure" > configure.log
make -j"$JOBS" isa RISCV_PREFIX="$RISCV_PREFIX" XLEN=64 > build.log
# rv64ua: upstream needs -march=..._zacas_zabha (GCC 15+). Build the classic
# AMO/LR-SC tests with rv64g so atomics stay covered on GCC 14.
cd "$TESTS_BIN"
for f in "$S"/rv64ua/*.S; do
  n=$(basename "$f" .S); case $n in amocas*|*_b|*_h) continue;; esac
  [ -f "rv64ua-p-$n" ] && continue
  ${RISCV_PREFIX}gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden \
    -nostdlib -nostartfiles -I"$S/../env/p" -I"$S/macros/scalar" -T"$S/../env/p/link.ld" "$f" -o "rv64ua-p-$n"
done
# Benchmarks (printf over HTIF) + demo hello, used by the browser demo.
B="$TESTS_SRC/benchmarks"; mkdir -p "$BENCH_BIN"
CF="-I$B/../env -I$B/common -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns -march=rv64gc -mabi=lp64d"
LF="-static -nostdlib -nostartfiles -lm -lgcc -T $B/common/test.ld"
for b in dhrystone median qsort rsort towers multiply spmv vvadd memcpy mm; do
  ${RISCV_PREFIX}gcc $CF -Wno-implicit-int -Wno-implicit-function-declaration -Wno-int-conversion -I"$B/$b" \
    -o "$BENCH_BIN/$b.riscv" "$B/$b"/*.c "$B"/common/*.c "$B"/common/*.S $LF
done
${RISCV_PREFIX}gcc $CF -o "$BENCH_BIN/hello.riscv" "$ROOT/demo/src/hello.c" "$B/common/syscalls.c" "$B/common/crt.S" $LF
log "tests: $(ls "$TESTS_BIN" | grep -vc dump) ISA tests, $(ls "$BENCH_BIN" | wc -l) benchmark ELFs"
