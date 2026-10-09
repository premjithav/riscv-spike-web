#!/usr/bin/env bash
# Install host deps + activate the Emscripten SDK (one-time)
set -euo pipefail
source "$(dirname "$0")/env.sh"
sudo apt-get update
sudo apt-get install -y build-essential autoconf device-tree-compiler git python3 nodejs \
  gcc-riscv64-unknown-elf
git -C "$ROOT" submodule update --init --recursive
cd "$EMSDK" && ./emsdk install latest && ./emsdk activate latest
echo "Done. Run: source $EMSDK/emsdk_env.sh"
