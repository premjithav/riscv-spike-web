#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# One-time setup: submodules, RISC-V GCC (xPack), dtc check, Emscripten.
# Safe to re-run; installed parts are skipped.
#   ./scripts/setup-tools.sh [--install-deps]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ "${1:-}" = "--install-deps" ]; then
  echo "==> apt-get install build dependencies (needs sudo)"
  sudo apt-get update
  sudo apt-get install -y build-essential git curl python3 xz-utils device-tree-compiler
fi

for c in git make gcc g++ curl python3 tar; do
  command -v "$c" >/dev/null || { echo "Missing '$c'. Install the packages listed in docs/SETUP.md (or re-run with --install-deps)."; exit 1; }
done

echo "==> submodules"
git -C "$ROOT" submodule update --init --recursive

source "$ROOT/scripts/env.sh"

echo "==> RISC-V GCC (xPack $XPACK_GCC_VERSION)"
if [ ! -x "$ROOT/tools/riscv-none-elf-gcc/bin/riscv-none-elf-gcc" ]; then
  case "$(uname -m)" in
    x86_64)  arch=linux-x64 ;;
    aarch64) arch=linux-arm64 ;;
    *) echo "No prebuilt xPack GCC for $(uname -m); install a riscv64 bare-metal GCC and set RISCV_PREFIX."; exit 1 ;;
  esac
  mkdir -p "$ROOT/tools"
  curl -fSL -C - -o "$ROOT/tools/xpack-gcc.tgz" \
    "https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v$XPACK_GCC_VERSION/xpack-riscv-none-elf-gcc-$XPACK_GCC_VERSION-$arch.tar.gz"
  tar xzf "$ROOT/tools/xpack-gcc.tgz" -C "$ROOT/tools"
  mv "$ROOT/tools/xpack-riscv-none-elf-gcc-$XPACK_GCC_VERSION" "$ROOT/tools/riscv-none-elf-gcc"
  rm "$ROOT/tools/xpack-gcc.tgz"
else
  echo "    already installed"
fi

echo "==> dtc"
command -v dtc >/dev/null || { echo "dtc missing: sudo apt-get install device-tree-compiler (or put a static dtc in tools/bin)"; exit 1; }
dtc --version

echo "==> Emscripten $EMSDK_VERSION (downloads from storage.googleapis.com)"
if [ -x "$EMSDK/upstream/emscripten/emcc" ] && grep -q "$EMSDK_VERSION" "$EMSDK/upstream/emscripten/emscripten-version.txt" 2>/dev/null; then
  echo "    already installed"
else
  (cd "$EMSDK" && ./emsdk install "$EMSDK_VERSION")
fi
(cd "$EMSDK" && ./emsdk activate "$EMSDK_VERSION" >/dev/null)

echo "==> setup complete. Next: ./scripts/build-all.sh"
