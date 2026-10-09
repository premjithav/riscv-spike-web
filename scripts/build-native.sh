#!/usr/bin/env bash
# Native reference Spike + DTB. Resumable: re-run if interrupted.
set -euo pipefail
source "$(dirname "$0")/env.sh"
B="$BUILD_ROOT/native"; mkdir -p "$B" && cd "$B"
[ -f Makefile ] || CFLAGS=-O2 CXXFLAGS=-O2 "$SPIKE_SRC/configure" --prefix="$NATIVE_PREFIX"
make -j"$(nproc)"
mkdir -p "$NATIVE_PREFIX/bin"
strip -o "$NATIVE_PREFIX/bin/spike" spike
strip -o "$NATIVE_PREFIX/bin/spike-dasm" spike-dasm
echo 'x' > /tmp/spike-dummy
"$NATIVE_PREFIX/bin/spike" --isa="$ISA" -m"$MEM" --dump-dts /tmp/spike-dummy > "$ROOT/spike.dts"
dtc -q -I dts -O dtb -o "$ROOT/spike.dtb" "$ROOT/spike.dts"
echo "spike: $NATIVE_PREFIX/bin/spike  DTB: $ROOT/spike.dtb"
