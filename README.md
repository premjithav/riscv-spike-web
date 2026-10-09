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
./scripts/test-wasm.sh              # run suite under node
./scripts/build-wasm.sh web         # dist/spike-web.js for the browser
```
Override ISA/memory with `ISA=rv32gc MEM=128 ./scripts/...` (rebuild the DTB if you change them).

Notes: wasm can't fork `dtc`, so always pass `--dtb=spike.dtb`; `-fwasm-exceptions` is required because Spike throws on every trap.
