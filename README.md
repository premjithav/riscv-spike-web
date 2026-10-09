# spikey — Spike (RISC-V ISA simulator) → WebAssembly

Tools are git submodules under `third_party/`:

| Path | Upstream |
|---|---|
| third_party/riscv-isa-sim | riscv-software-src/riscv-isa-sim |
| third_party/riscv-tests | riscv-software-src/riscv-tests |
| third_party/emsdk | emscripten-core/emsdk |

## Steps
```bash
./scripts/setup-tools.sh            # apt deps + emsdk install/activate
./scripts/build-native.sh           # reference spike + spike.dtb
./scripts/build-tests.sh            # riscv-tests ISA suite
./scripts/build-wasm.sh node        # dist/spike.js + spike.wasm
./scripts/run-suite.sh wasm         # run suite under node (native: run-suite.sh native)
./scripts/build-wasm.sh web         # dist/spike-web.js for the browser
```
Override ISA/memory with `ISA=rv32gc MEM=128 ./scripts/...` (rebuild the DTB if you change them).

Notes: wasm can't fork `dtc`, so always pass `--dtb=spike.dtb`; `-fwasm-exceptions` is required because Spike throws on every trap.

## Status
- Native Spike builds; `run-suite.sh native` → 90/90 rv64u{i,m,a,f,d,c}-p pass (`ma_data` skipped).
- `spike.dts` / `spike.dtb` are committed (rv64gc, 256 MB) — regenerate if ISA/MEM change.
- `tools/` (git-ignored) holds a static `dtc` and the xPack `riscv-none-elf-gcc` 14.2.0-3.
- emsdk needs `storage.googleapis.com` reachable to install.

## Building inside the Claude Cowork VM
Shared-folder I/O is slow and limits open files, so build objects on VM-local disk:
`BUILD_ROOT=$HOME/work ./scripts/build-native.sh` (re-run to resume; each shell call is time-limited).
