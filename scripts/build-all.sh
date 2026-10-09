#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Full pipeline for the current Spike commit. Each step is resumable.
set -euo pipefail
D="$(dirname "$0")"
"$D/build-native.sh"
"$D/build-tests.sh"
"$D/build-wasm.sh"
"$D/verify.sh"
"$D/build-demo.sh"
