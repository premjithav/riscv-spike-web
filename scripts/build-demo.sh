#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
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
mkdir -p "$S/licenses"
cp "$ROOT/LICENSE" "$S/licenses/riscv-spike-web.txt"
cp "$SPIKE_SRC/LICENSE" "$S/licenses/riscv-isa-sim.txt"
cp "$TESTS_SRC/LICENSE" "$S/licenses/riscv-tests.txt"
cp "$EMSDK/LICENSE" "$S/licenses/emsdk.txt"
ls -la "$S" "$S/licenses"
log "demo ready in demo/site (spike $SPIKE_SHA)"
