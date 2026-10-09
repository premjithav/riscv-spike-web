#!/usr/bin/env bash
# Assemble the browser demo in demo/site/: page + worker + wasm + bundle.json
# (programs, per-ISA DTBs, build info). Serve with: python3 -m http.server -d demo/site
set -euo pipefail
source "$(dirname "$0")/env.sh"
S="$ROOT/demo/site"; mkdir -p "$S"
cp "$ROOT/demo/web/index.html" "$ROOT/demo/web/worker.js" "$S/"
cp "$DIST/web/spike.js" "$S/spike-web.js"
cp "$DIST/web/spike.wasm" "$S/spike-web.wasm"
EMCC_VER=$(tr -d "\"\n" < "$EMSDK/upstream/emscripten/emscripten-version.txt" 2>/dev/null || true)
python3 "$ROOT/demo/make-bundle.py" --programs "$ROOT/demo/programs.json" \
  --tests "$TESTS_BIN" --bench "$BENCH_BIN" --dtb "$DTB_DIR" --isas $DEMO_ISAS \
  --spike "$SPIKE_SHA" --emscripten "${EMCC_VER:-unknown}" --verify "$DIST/verify.json" --out "$S/bundle.json"
ls -la "$S"
log "demo ready in demo/site (spike $SPIKE_SHA)"
