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
- Native and wasm (Node) Spike both pass 109/109 rv64u{i,m,a,f,d,c}-p tests (`ma_data` skipped: misaligned access not emulated by default; fails identically on both).
- Instruction traces (`-l`) are byte-identical native vs wasm on all 121 tests incl. zfh.
- wasm32 source fix: `patches/riscv-isa-sim-wasm32.patch` (applied by build-wasm.sh).
- rv64ua: amocas/zabha tests skipped — xPack GCC 14 lacks zacas/zabha.
- `spike.dts` / `spike.dtb` committed (rv64gc, 256 MB).
- Emscripten 6.0.12 is installed in third_party/emsdk from the host (the Cowork VM can't reach storage.googleapis.com).

## Building inside the Claude Cowork VM
Shared-folder I/O is slow and limits open files, so build objects on VM-local disk:
`BUILD_ROOT=$HOME/work ./scripts/build-native.sh` (re-run to resume; each shell call is time-limited).

## Browser demo (`demo/`)
- `demo/web/index.html` + `worker.js`: page that runs Spike in a Web Worker (one worker per run; the wasm module is compiled once and shared).
- Browser link (no `--export-dynamic`, so JS is 91 KB and wasm 7.9 MB):
  `em++ -O2 -fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=4GB -sSTACK_SIZE=8MB -sMODULARIZE=1 -sEXPORT_NAME=createSpike -sINVOKE_RUN=0 -sEXIT_RUNTIME=1 -sFORCE_FILESYSTEM=1 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=FS,callMain extension.o spike.o libspike_main.a libriscv.a libdisasm.a libsoftfloat.a libfesvr.a libfdt.a -o spike-web.js`
- With `--dtb`, Spike takes the hart ISA from the device tree, so the demo ships one DTB per ISA (rv64gc, rv64imac, rv64gcv).
- `demo/src/hello.c`: bare-metal hello built against riscv-tests/benchmarks/common (printf over HTIF).
