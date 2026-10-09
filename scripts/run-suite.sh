#!/usr/bin/env bash
# Usage: run-suite.sh native|wasm   — runs rv64u{i,m,a,f,d,c}-p-* tests
set -uo pipefail
source "$(dirname "$0")/env.sh"
MODE="${1:-native}"
if [ "$MODE" = native ]; then SIM=("$NATIVE_PREFIX/bin/spike"); else SIM=(node "$ROOT/dist/spike.js"); fi
EXPECTED_FAIL="rv64ui-p-ma_data"   # misaligned access not emulated by default
pass=0; fail=0
for t in "$TESTS_BIN"/rv64u[imafdc]-p-*; do
  n=$(basename "$t"); [[ "$n" == *.dump ]] && continue
  [[ " $EXPECTED_FAIL " == *" $n "* ]] && continue
  if timeout 60 "${SIM[@]}" --isa="$ISA" -m"$MEM" --dtb="$ROOT/spike.dtb" "$t" >/dev/null 2>&1; then
    pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $n"; fi
done
echo "$MODE: PASS=$pass FAIL=$fail (skipped: $EXPECTED_FAIL)"
[ "$fail" -eq 0 ]
