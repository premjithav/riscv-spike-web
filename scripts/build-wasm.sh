#!/usr/bin/env bash
# Usage: build-wasm.sh [node|web]   — resumable; re-run if interrupted
set -euo pipefail
source "$(dirname "$0")/env.sh"
TARGET="${1:-node}"
source "$EMSDK/emsdk_env.sh" >/dev/null 2>&1
# wasm32 fixes for Spike (idempotent)
git -C "$SPIKE_SRC" apply --check "$ROOT/patches/riscv-isa-sim-wasm32.patch" 2>/dev/null \
  && git -C "$SPIKE_SRC" apply "$ROOT/patches/riscv-isa-sim-wasm32.patch" || true
COMMON="-fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=4GB -sSTACK_SIZE=8MB"
if [ "$TARGET" = node ]; then
  LINK="$COMMON -sEXIT_RUNTIME=1 -sNODERAWFS=1"; OUT=spike.js
else
  LINK="$COMMON -sMODULARIZE=1 -sEXPORT_NAME=createSpike -sINVOKE_RUN=0 -sFORCE_FILESYSTEM=1 \
 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=FS,callMain"; OUT=spike-web.js
fi
B="$BUILD_ROOT/wasm"; mkdir -p "$B" && cd "$B"
if [ ! -f Makefile ]; then
  CFLAGS="-O2 -fwasm-exceptions" CXXFLAGS="-O2 -fwasm-exceptions" LDFLAGS="-fwasm-exceptions" \
  emconfigure "$SPIKE_SRC/configure" --host=wasm32-unknown-emscripten \
    --without-boost --without-boost-asio --without-boost-regex
fi
# an interrupted compile can leave empty objects behind
find . -maxdepth 1 \( -name '*.o' -o -name '*.d' \) -size 0 -delete
emmake make -j"$(nproc)" spike
rm -f spike spike.wasm
emmake make spike LDFLAGS="$LINK"
mkdir -p "$ROOT/dist"
cp spike "$ROOT/dist/$OUT"; cp spike.wasm "$ROOT/dist/spike.wasm"
echo "Output: $ROOT/dist/$OUT + spike.wasm"
