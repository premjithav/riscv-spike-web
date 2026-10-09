#!/usr/bin/env bash
# Gate for any Spike update: native and wasm must pass the suite, and the wasm
# instruction trace (-l) must be byte-identical to native on every test.
# Writes dist/verify.json (read by the demo bundle).
set -uo pipefail
source "$(dirname "$0")/env.sh"
log "verify spike $SPIKE_SHA"
"$ROOT/scripts/run-suite.sh" native | tail -1 | tee /tmp/spikey-native.txt; n_ok=${PIPESTATUS[0]}
"$ROOT/scripts/run-suite.sh" wasm   | tail -1 | tee /tmp/spikey-wasm.txt;   w_ok=${PIPESTATUS[0]}
same=0; diff=""
for t in "$TESTS_BIN"/rv64u[imafdc]-p-*; do
  [[ "$t" == *.dump ]] && continue
  a=$("$NATIVE_PREFIX/bin/spike" -l --isa="$ISA" -m"$MEM" --dtb="$DTB_DIR/$ISA.dtb" "$t" 2>&1 | md5sum)
  b=$(node "$DIST/node/spike.js" -l --isa="$ISA" -m"$MEM" --dtb="$DTB_DIR/$ISA.dtb" "$t" 2>&1 | md5sum)
  [ "$a" = "$b" ] && same=$((same+1)) || diff="$diff $(basename "$t")"
done
echo "traces identical: $same, different:${diff:- none}"
passed=$(sed -n 's/.*PASS=\([0-9]*\).*/\1/p' /tmp/spikey-wasm.txt)
mkdir -p "$DIST"
printf '{"spike":"%s","tests_passed":%s,"traces_identical":%s,"traces_different":"%s","date":"%s"}\n' \
  "$SPIKE_SHA" "${passed:-0}" "$same" "${diff# }" "$(date -u +%Y-%m-%d)" > "$DIST/verify.json"
[ "$n_ok" -eq 0 ] && [ "$w_ok" -eq 0 ] && [ -z "$diff" ] && { log "verify PASSED"; exit 0; }
log "verify FAILED"; exit 1
