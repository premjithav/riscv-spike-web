# spikey — Spike (RISC-V ISA simulator) → WebAssembly

Builds upstream Spike for Node and the browser **without modifying Spike's sources**.
`third_party/riscv-isa-sim` stays a pristine upstream checkout; every wasm-specific
choice lives in `scripts/env.sh` and the demo's JavaScript.

| Path | What |
|---|---|
| `third_party/riscv-isa-sim` | Spike, upstream (submodule, never edited) |
| `third_party/riscv-tests` | ISA tests + benchmarks (submodule) |
| `third_party/emsdk` | Emscripten SDK (submodule; toolchain installed locally, 6.0.12) |
| `scripts/` | build, verify and update pipeline |
| `demo/web/` | browser demo source (page + Web Worker) |
| `demo/programs.json`, `demo/make-bundle.py` | which programs the demo ships, and the bundler |
| `tools/` *(ignored)* | static `dtc`, xPack `riscv-none-elf-gcc` 14.2.0-3 |

## One-time setup
```bash
git submodule update --init --recursive --depth 1
./scripts/setup-tools.sh                       # RISC-V GCC, dtc check, emsdk install/activate
```

## Build everything for the current Spike commit
```bash
./scripts/build-all.sh     # native → tests → wasm → verify → demo
python3 -m http.server -d demo/site 8080       # open http://localhost:8080
```
Steps (each resumable, safe to re-run):

| Script | Output |
|---|---|
| `build-native.sh` | `install/native/bin/spike`, `dtb/<isa>.dtb` (rv64gc, rv64imac, rv64gcv) |
| `build-tests.sh` | `build/tests/isa/*` (incl. rv64ua via rv64g), `build/bench/*.riscv`, `hello.riscv` |
| `build-wasm.sh` | `dist/node/spike.{js,wasm}`, `dist/web/spike.{js,wasm}` |
| `verify.sh` | gate: native + wasm pass the rv64u* suite, `-l` traces byte-identical; writes `dist/verify.json` |
| `build-demo.sh` | `demo/site/` ready to serve or publish (build info embedded in `bundle.json`) |

Build directories are per Spike commit: `build/spike-<sha12>/{native,wasm}` (set `BUILD_ROOT` for a faster disk).

## Updating Spike
```bash
./scripts/update-spike.sh            # latest upstream master
./scripts/update-spike.sh <sha|tag>  # specific ref
```
Moves the submodule, runs `build-all.sh` in a fresh build dir, and commits the new
submodule pointer only if `verify.sh` passes. On any failure it restores the previous
commit and keeps the failed build dir for inspection. It refuses to run if the
submodule has local edits.

## How the port works without source changes
- **64→32-bit narrowing** (`riscv/mmu.cc`, TLB refill): clang treats it as a default-error
  warning on wasm32; `-Wno-c++11-narrowing` restores the intended 32-bit truncation.
- **C++ exceptions**: Spike throws on every trap → `-fwasm-exceptions`.
- **`--export-dynamic`** (added by Spike's configure for `--extlib`): dropped by overriding
  the `mcppbs-LDFLAGS` make variable at link time → browser JS 91 KB, wasm 7.9 MB.
- **Device tree**: wasm can't fork `dtc`, so DTBs are generated natively and passed with
  `--dtb`. Spike takes the hart ISA from the DTB, hence one DTB per ISA.
- **Interactive debugger in the browser** (`-d`): commands are replayed from reset
  (Spike is deterministic). Spike reads debugger input from fd 2; the worker routes
  `FS.read` on fd 2 to stdin.

## Status (spike d6cfe9efdb53, emscripten 6.0.12)
- Native and wasm: 109/109 rv64u{i,m,a,f,d,c}-p (`ma_data` skipped: misaligned access not emulated by default).
- Instruction traces identical native vs wasm on 110 tests.
- rv64ua `amocas*` skipped: GCC 14 lacks Zacas.

## Building inside the Claude Cowork VM
Shell calls there are time-limited: use `BUILD_ROOT=$HOME/work` (VM-local disk; the shared
folder is slow and limits open files) and re-run a step until it finishes.
