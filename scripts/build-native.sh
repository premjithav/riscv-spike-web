#!/usr/bin/env bash
# Native reference Spike + DTB for the wasm build
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$ROOT/build/native" && cd "$ROOT/build/native"
"$SPIKE_SRC/configure" --prefix="$NATIVE_PREFIX"
make -j"$(nproc)" && make install
"$NATIVE_PREFIX/bin/spike" --isa="$ISA" -m"$MEM" --dump-dts /bin/true > "$ROOT/spike.dts"
dtc -I dts -O dtb -o "$ROOT/spike.dtb" "$ROOT/spike.dts"
echo "DTB: $ROOT/spike.dtb"
