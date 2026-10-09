#!/usr/bin/env bash
# Spike -> WebAssembly with Emscripten, no source changes. Produces
#   dist/node/spike.js + spike.wasm   (Node, direct file access)
#   dist/web/spike.js  + spike.wasm   (browser / Web Worker, MODULARIZE createSpike)
# Resumable: re-run if interrupted.
set -euo pipefail
source "$(dirname "$0")/env.sh"
source "$EMSDK/emsdk_env.sh" >/dev/null 2>&1
command -v emcc >/dev/null || { echo "emcc not found: install emsdk in third_party/emsdk (./emsdk install 6.0.12 && ./emsdk activate 6.0.12)"; exit 1; }
B="$BUILD_DIR/wasm"; mkdir -p "$B" && cd "$B"
log "wasm spike $SPIKE_SHA in $B ($(emcc --version | head -1 | cut -c1-60))"
if [ ! -f Makefile ]; then
  CFLAGS="$WASM_CFLAGS" CXXFLAGS="$WASM_CFLAGS" LDFLAGS="-fwasm-exceptions" \
  emconfigure "$SPIKE_SRC/configure" --host=wasm32-unknown-emscripten \
    --without-boost --without-boost-asio --without-boost-regex > configure.log
fi
# An interrupted compile can leave empty objects behind.
find . -maxdepth 1 \( -name '*.o' -o -name '*.d' \) -size 0 -delete
make -j"$JOBS" spike > build.log

link() {  # $1 = target dir, $2 = link flags
  rm -f spike spike.wasm
  make spike mcppbs-LDFLAGS="$WASM_MCPPBS_LDFLAGS" LDFLAGS="$2" > /dev/null
  mkdir -p "$1"; cp spike "$1/spike.js"; cp spike.wasm "$1/spike.wasm"
  echo "$SPIKE_SHA" > "$1/SPIKE_COMMIT"
}
link "$DIST/node" "$WASM_NODE_LINK"
link "$DIST/web"  "$WASM_WEB_LINK"
ls -la "$DIST/node" "$DIST/web"
log "wasm done"
