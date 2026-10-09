#!/usr/bin/env bash
# Usage: build-wasm.sh [node|web]
set -euo pipefail
source "$(dirname "$0")/env.sh"
TARGET="${1:-node}"
source "$EMSDK/emsdk_env.sh" >/dev/null
COMMON="-fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=4GB -sSTACK_SIZE=8MB"
if [ "$TARGET" = node ]; then
  LINK="$COMMON -sEXIT_RUNTIME=1 -sNODERAWFS=1"
else
  LINK="$COMMON -sMODULARIZE=1 -sEXPORT_NAME=createSpike -sINVOKE_RUN=0 -sFORCE_FILESYSTEM=1 \
 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=FS,callMain"
fi
B="$ROOT/build/wasm"; mkdir -p "$B" && cd "$B"
if [ ! -f Makefile ]; then
  CFLAGS="-O3 -fwasm-exceptions" CXXFLAGS="-O3 -fwasm-exceptions" LDFLAGS="$LINK" \
  emconfigure "$SPIKE_SRC/configure" --host=wasm32-unknown-emscripten \
    --without-boost --without-boost-asio --without-boost-regex
fi
rm -f spike
emmake make -j"$(nproc)" spike LDFLAGS="$LINK"
mkdir -p "$ROOT/dist"
if [ "$TARGET" = node ]; then cp spike "$ROOT/dist/spike.js"; else cp spike "$ROOT/dist/spike-web.js"; fi
cp spike.wasm "$ROOT/dist/"
echo "Output in $ROOT/dist"
