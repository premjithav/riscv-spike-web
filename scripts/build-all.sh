#!/usr/bin/env bash
# Full pipeline for the current Spike commit. Each step is resumable.
set -euo pipefail
D="$(dirname "$0")"
"$D/build-native.sh"
"$D/build-tests.sh"
"$D/build-wasm.sh"
"$D/verify.sh"
"$D/build-demo.sh"
