#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TESTS_SRC" && autoconf && ./configure && make -C isa -j"$(nproc)"
