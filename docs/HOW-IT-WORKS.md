# How it works

## Goal: no changes to Spike

`third_party/riscv-isa-sim` is a plain upstream checkout. Everything needed to build it
for WebAssembly is a flag in `scripts/env.sh` or code in the demo. That keeps updates to
new Spike releases a one-command job (see [UPDATING-SPIKE.md](UPDATING-SPIKE.md)).

## Build

Spike's own autoconf build is used unchanged, out of tree, through Emscripten:

```
emconfigure riscv-isa-sim/configure --host=wasm32-unknown-emscripten \
    --without-boost --without-boost-asio --without-boost-regex
make spike
```

with these settings:

| Problem on wasm32 | Fix (no source change) |
|---|---|
| Spike throws a C++ exception on every trap | `-fwasm-exceptions` (native Wasm exception handling) |
| `riscv/mmu.cc` stores `host_addr - offset` (64-bit `reg_t` arithmetic) in a `uintptr_t`, which is 32-bit on wasm32. Clang reports `-Wc++11-narrowing` as an error. | `-Wno-c++11-narrowing`. The value is a 32-bit host address, so the truncation is exactly the intended arithmetic. |
| Spike's configure adds `-Wl,--export-dynamic` (for `--extlib` plugins), which exports every symbol: 9.5 MB of JS glue and a 19 MB `.wasm` | Override the `mcppbs-LDFLAGS` make variable on the command line at link time. Result: 91 KB JS, 7.9 MB wasm. `--extlib` can't work in a browser anyway. |
| Spike runs `dtc` (fork + exec) to compile its device tree | Not possible in wasm. `build-native.sh` dumps the DTS with native Spike (`--dump-dts`), compiles it with `dtc`, and the wasm build is always run with `--dtb=`. |
| Memory | `-sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=4GB`. Spike allocates guest pages lazily, so `-m256` doesn't reserve 256 MB up front. |

Two links are made from the same objects:

- `dist/node/`: `-sNODERAWFS=1 -sEXIT_RUNTIME=1`. Behaves like the native binary,
  with direct access to the host file system.
- `dist/web/`: `-sMODULARIZE=1 -sEXPORT_NAME=createSpike -sINVOKE_RUN=0
  -sENVIRONMENT=web,worker`, with `FS` and `callMain` exported. The page writes the ELF and
  DTB into the in-memory file system and calls `callMain(args)`.

### The DTB decides the ISA

When `--dtb` is given, Spike configures the hart from the device tree's `riscv,isa`
property, so `--isa` alone has no effect. The build therefore generates one DTB per ISA
(`dtb/rv64gc.dtb`, `dtb/rv64imac.dtb`, `dtb/rv64gcv.dtb`), and the demo picks the one that
matches its ISA menu.

## Verification

`scripts/verify.sh` is the gate for every build and every Spike update:

1. the riscv-tests rv64u{i,m,a,f,d,c} physical-memory tests pass on native Spike;
2. they pass on the Node.js wasm build;
3. for every test, the `-l` instruction trace of the wasm build is byte-identical to native.

`rv64ui-p-ma_data` is skipped (Spike doesn't emulate misaligned accesses by default; it
fails the same way on both builds). The rv64ua tests are built with `-march=rv64g`, because
the upstream Makefile asks for Zacas/Zabha, which GCC 14 doesn't support.

## Browser demo

`demo/web/index.html` is a single page with no dependencies. It fetches `spike-web.wasm`
once, compiles it to a `WebAssembly.Module`, and starts a fresh Web Worker
(`demo/web/worker.js`) for every run. The worker instantiates the shared module (fast),
writes the ELF and DTB, and calls `callMain`. Output is batched every 60 ms; the
instruction trace is capped at 4,000 lines.

`bundle.json` carries the demo programs, the per-ISA DTBs and the build info (Spike commit,
Emscripten version, `verify.json`), which the page shows in its header and notes.

### Debug mode: replay instead of blocking

Spike's interactive debugger (`-d`) reads commands with a blocking `read()`. A browser
can't block a WebAssembly call until the user types something, without cross-origin
isolation headers that hosting services such as GitHub Pages don't send.

Spike is deterministic, though: the same program, DTB and commands always produce the
same state. So the page keeps a command history and, for every new command, re-runs the
program from reset with the whole history on stdin, then a hidden `pc 0` (for the status
bar) and `q`. The transcript of the replay is the session. This also gives **Undo** for
free: drop the last command and replay.

Two details make this work:

- Spike's debugger reads from **fd 2** (on a terminal, stderr is readable). Emscripten's
  stderr has no input side, so the worker wraps `FS.read` and routes reads on fd 2 to the
  stdin device.
- The worker inserts a marker each time stdin starts delivering a new command line, so
  the page knows which output belongs to which command, and drops Spike's prompt and
  keystroke echo.

Spike's `until`/`while` take hex addresses, so the page reads the ELF symbol table (ELF64,
`SHT_SYMTAB`) and replaces a trailing symbol name with its address before sending the
command (`until pc 0 main` → `until pc 0 0x80002a08`). The status bar shows the current PC
as `symbol+offset`.

Cost: each command replays everything before it. For the demo programs this takes
milliseconds; for a program that runs hundreds of millions of instructions before the
point of interest, each step costs that much again.
