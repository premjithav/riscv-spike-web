# Common settings — sourced by every script. Nothing here modifies third_party/.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPIKE_SRC="$ROOT/third_party/riscv-isa-sim"
TESTS_SRC="$ROOT/third_party/riscv-tests"
EMSDK="$ROOT/third_party/emsdk"
SPIKE_SHA="$(git -C "$SPIKE_SRC" rev-parse --short=12 HEAD)"

# Out-of-tree builds, one directory per Spike commit (fresh build after every update).
# BUILD_ROOT can point at a faster local disk.
BUILD_ROOT="${BUILD_ROOT:-$ROOT/build}"
BUILD_DIR="$BUILD_ROOT/spike-$SPIKE_SHA"
NATIVE_PREFIX="$ROOT/install/native"     # current native spike
DIST="$ROOT/dist"                          # current wasm builds: dist/node, dist/web
DTB_DIR="$ROOT/dtb"                        # generated device trees, one per ISA
TESTS_BIN="$ROOT/build/tests/isa"
BENCH_BIN="$ROOT/build/bench"

ISA="${ISA:-rv64gc}"                       # default hart for tests
DEMO_ISAS="${DEMO_ISAS:-rv64gc rv64imac rv64gcv}"
MEM="${MEM:-256}"
RISCV_PREFIX="${RISCV_PREFIX:-riscv-none-elf-}"

# wasm32 build: Spike narrows reg_t (64-bit) to uintptr_t (32-bit) in mmu.cc; clang makes
# that a default-error warning. Truncation is the intended 32-bit arithmetic, so allow it
# instead of patching the source.
WASM_CFLAGS="-O2 -fwasm-exceptions -Wno-c++11-narrowing"
WASM_COMMON_LINK="-fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=4GB -sSTACK_SIZE=8MB"
WASM_NODE_LINK="$WASM_COMMON_LINK -sEXIT_RUNTIME=1 -sNODERAWFS=1"
WASM_WEB_LINK="-O2 $WASM_COMMON_LINK -sMODULARIZE=1 -sEXPORT_NAME=createSpike -sINVOKE_RUN=0 -sEXIT_RUNTIME=1 \
 -sFORCE_FILESYSTEM=1 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=FS,callMain"
# Spike's configure adds -Wl,--export-dynamic (for --extlib plugins). Overriding this make
# variable on the command line drops it: 9.5 MB -> 91 KB of JS, 19 MB -> 7.9 MB of wasm.
WASM_MCPPBS_LDFLAGS="-fwasm-exceptions"

export PATH="$ROOT/tools/bin:$ROOT/tools/riscv-none-elf-gcc/bin:$PATH"
ulimit -n "$(ulimit -Hn)" 2>/dev/null || true
JOBS="${JOBS:-$(nproc)}"

log() { printf '\n==> %s\n' "$*"; }
