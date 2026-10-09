#!/usr/bin/env bash
# Run riscv-tests ISA suite on the wasm Spike under Node
set -euo pipefail
source "$(dirname "$0")/env.sh"
pass=0; fail=0
for t in "$TESTS_SRC"/isa/rv64u[imafdc]-p-*; do
  [[ "$t" == *.dump ]] && continue
  if node "$ROOT/dist/spike.js" --isa="$ISA" -m"$MEM" --dtb="$ROOT/spike.dtb" "$t" >/dev/null 2>&1; then
    pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $(basename "$t")"; fi
done
echo "PASS=$pass FAIL=$fail"
