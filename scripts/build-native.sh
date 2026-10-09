#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Native reference Spike + one DTB per ISA. Resumable: re-run if interrupted.
set -euo pipefail
source "$(dirname "$0")/env.sh"
B="$BUILD_DIR/native"; mkdir -p "$B" && cd "$B"
log "native spike $SPIKE_SHA in $B"
[ -f Makefile ] || CFLAGS=-O2 CXXFLAGS=-O2 "$SPIKE_SRC/configure" --prefix="$NATIVE_PREFIX" > configure.log
make -j"$JOBS"
mkdir -p "$NATIVE_PREFIX/bin"
strip -o "$NATIVE_PREFIX/bin/spike" spike
strip -o "$NATIVE_PREFIX/bin/spike-dasm" spike-dasm
mkdir -p "$DTB_DIR"
echo x > "$B/dummy.elf"
for isa in $DEMO_ISAS $ISA; do
  "$NATIVE_PREFIX/bin/spike" --isa="$isa" -m"$MEM" --dump-dts "$B/dummy.elf" > "$DTB_DIR/$isa.dts"
  dtc -q -I dts -O dtb -o "$DTB_DIR/$isa.dtb" "$DTB_DIR/$isa.dts"
done
echo "$SPIKE_SHA" > "$NATIVE_PREFIX/SPIKE_COMMIT"
log "native done: $NATIVE_PREFIX/bin/spike, DTBs in $DTB_DIR"
