#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Move third_party/riscv-isa-sim to a new upstream ref, rebuild everything from
# scratch, and keep the update only if verify.sh passes. On failure the
# submodule goes back to the previous commit.
#   ./scripts/update-spike.sh            # latest upstream master
#   ./scripts/update-spike.sh <sha|tag>  # a specific ref
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPIKE="$ROOT/third_party/riscv-isa-sim"
REF="${1:-master}"
[ -z "$(git -C "$SPIKE" status --porcelain)" ] || { echo "third_party/riscv-isa-sim has local changes; this flow expects pristine upstream sources."; exit 1; }
OLD=$(git -C "$SPIKE" rev-parse HEAD)
git -C "$SPIKE" fetch --depth 1 origin "$REF"
NEW=$(git -C "$SPIKE" rev-parse FETCH_HEAD)
[ "$OLD" = "$NEW" ] && { echo "Already at $REF ($NEW)."; exit 0; }
echo "Updating riscv-isa-sim ${OLD:0:12} -> ${NEW:0:12} ($REF)"
git -C "$SPIKE" checkout -q --detach "$NEW"
if "$ROOT/scripts/build-all.sh"; then
  git -C "$ROOT" add third_party/riscv-isa-sim
  git -C "$ROOT" commit -q -m "Update riscv-isa-sim to ${NEW:0:12} ($REF)

Native and wasm pass the rv64u* suite; wasm traces identical to native (scripts/verify.sh)."
  echo "Updated and committed. Republish demo/site if you host the demo."
else
  echo "Build or verification failed for ${NEW:0:12}; restoring ${OLD:0:12}. Build dir kept for inspection: build/spike-${NEW:0:12}"
  git -C "$SPIKE" checkout -q --detach "$OLD"
  exit 1
fi
