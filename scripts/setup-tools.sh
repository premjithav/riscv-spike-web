#!/usr/bin/env bash
# One-time: submodules, RISC-V GCC (xPack), dtc check, emsdk
set -euo pipefail
source "$(dirname "$0")/env.sh"
git -C "$ROOT" submodule update --init --recursive --depth 1
mkdir -p "$ROOT/tools/bin"
if [ ! -x "$ROOT/tools/riscv-none-elf-gcc/bin/riscv-none-elf-gcc" ]; then
  V=14.2.0-3
  curl -fSL -C - -o "$ROOT/tools/xpack-gcc.tgz" \
    "https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v$V/xpack-riscv-none-elf-gcc-$V-linux-x64.tar.gz"
  tar xzf "$ROOT/tools/xpack-gcc.tgz" -C "$ROOT/tools"
  mv "$ROOT/tools/xpack-riscv-none-elf-gcc-$V" "$ROOT/tools/riscv-none-elf-gcc"
  rm "$ROOT/tools/xpack-gcc.tgz"
fi
command -v dtc >/dev/null || { echo "dtc missing: apt install device-tree-compiler, or put a static dtc in tools/bin"; exit 1; }
# emsdk downloads from storage.googleapis.com — must be reachable
cd "$EMSDK" && ./emsdk install 6.0.12 && ./emsdk activate 6.0.12
