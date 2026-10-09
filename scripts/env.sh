# Common paths — source this from other scripts
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPIKE_SRC="$ROOT/third_party/riscv-isa-sim"
TESTS_SRC="$ROOT/third_party/riscv-tests"
EMSDK="$ROOT/third_party/emsdk"
NATIVE_PREFIX="$ROOT/install/native"
# Object files are large; BUILD_ROOT can point at a fast local disk
BUILD_ROOT="${BUILD_ROOT:-$ROOT/build}"
TESTS_BIN="$ROOT/build/tests/isa"
ISA="${ISA:-rv64gc}"
MEM="${MEM:-256}"
RISCV_PREFIX="${RISCV_PREFIX:-riscv-none-elf-}"
export PATH="$ROOT/tools/bin:$ROOT/tools/riscv-none-elf-gcc/bin:$PATH"
ulimit -n "$(ulimit -Hn)" 2>/dev/null || true
