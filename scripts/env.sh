# Common paths — source this from other scripts
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPIKE_SRC="$ROOT/third_party/riscv-isa-sim"
TESTS_SRC="$ROOT/third_party/riscv-tests"
EMSDK="$ROOT/third_party/emsdk"
NATIVE_PREFIX="$ROOT/install/native"
ISA="${ISA:-rv64gc}"
MEM="${MEM:-256}"
