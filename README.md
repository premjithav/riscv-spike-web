# riscv-spike-web

**[Spike](https://github.com/riscv-software-src/riscv-isa-sim), the RISC-V ISA simulator, compiled to WebAssembly.**
Run RISC-V programs in Node.js or in a browser tab, and step through them with
Spike's own interactive debugger, with no server-side simulation.

- **Unmodified upstream Spike.** Spike is a git submodule that is never edited; every
  WebAssembly-specific choice is a compiler/linker flag or lives in the demo's JavaScript.
- **Verified against native.** Each build runs the riscv-tests ISA suite on native and wasm
  Spike and requires byte-identical instruction traces (`-l`).
- **One-command Spike updates.** `scripts/update-spike.sh` moves to a new upstream commit,
  rebuilds, verifies, and commits or rolls back.
- **Browser demo.** Pick a benchmark, ISA test or your own bare-metal ELF; choose the hart
  ISA; view an instruction trace; or debug with `until pc 0 main`, `reg`, `mem`, single
  step and undo.

| | |
|---|---|
| Spike | `d6cfe9efdb53` (riscv-isa-sim master, Oct 2026) |
| Emscripten | 6.0.12 |
| Tests | 109/109 rv64u{i,m,a,f,d,c}-p pass on native and wasm; traces identical on 110 tests |
| Browser build | `spike-web.js` 91 KB + `spike-web.wasm` 7.9 MB |

## Quick start (Ubuntu 22.04 / 24.04, x86_64)

```bash
git clone --recurse-submodules https://github.com/<you>/riscv-spike-web.git
cd riscv-spike-web
./scripts/setup-tools.sh --install-deps   # apt packages, RISC-V GCC, Emscripten (~2 GB, one time)
./scripts/build-all.sh                     # native + wasm Spike, tests, verify, demo (~20 min on 2 cores)
make serve                                 # open http://localhost:8080
```

Run a program with the Node.js build:

```bash
node dist/node/spike.js --isa=rv64gc -m256 --dtb=dtb/rv64gc.dtb build/bench/hello.riscv
```

The full walkthrough, including prerequisites and troubleshooting, is in
**[docs/SETUP.md](docs/SETUP.md)**.

## Using the demo

| Mode | What it does |
|---|---|
| **Run** | Runs the program to completion. Optional instruction trace (`-l`, first 4,000 instructions). |
| **Debug** | Starts `spike -d`, stopped at reset. Type debugger commands at the `(spike)` prompt; click a symbol to run to it; **Undo last** steps backwards. |

Useful debugger commands: Enter (step one instruction), `until pc 0 main`,
`while reg 0 a0 0`, `r 10`, `rs`, `reg 0`, `reg 0 sp`, `freg 0 fa0`, `mem 0 <addr>`,
`str 0 <addr>`, `insn 0`, `pc 0`. Symbol names are translated to addresses by the page.

Uploaded ELFs must be bare-metal RV64 programs linked at `0x80000000` that exit through
HTIF `tohost` (like riscv-tests). Linux user programs need the proxy kernel, which is not
included. See [demo/README.md](demo/README.md) to host the demo, for example on GitHub Pages.

## Repository layout

```
scripts/            build, verify and update pipeline (start with env.sh)
demo/web/           browser demo source: index.html + worker.js
demo/src/hello.c    the demo's hello program
demo/programs.json  programs bundled into the demo
docs/               setup, how it works, updating Spike
third_party/        riscv-isa-sim, riscv-tests, emsdk (submodules, never edited)
```

Generated and git-ignored: `tools/`, `build/`, `install/`, `dist/`, `dtb/`, `demo/site/`.

| Make target | Script |
|---|---|
| `make setup` | `scripts/setup-tools.sh` |
| `make all` | `scripts/build-all.sh` |
| `make verify` | `scripts/verify.sh` |
| `make serve` | serve `demo/site` on port 8080 |
| `make update` | `scripts/update-spike.sh` (latest upstream master) |

## Documentation

- [docs/SETUP.md](docs/SETUP.md): installation and build, step by step
- [docs/HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md): how Spike runs as wasm without source changes, and how browser debugging works
- [docs/UPDATING-SPIKE.md](docs/UPDATING-SPIKE.md): moving to a new Spike release
- [demo/README.md](demo/README.md): running and hosting the browser demo
- [CONTRIBUTING.md](CONTRIBUTING.md)

## Known limitations

- Single hart, bare-metal programs; no proxy kernel (`pk`) and no Linux boot in the demo.
- `rv64ui-p-ma_data` fails on both native and wasm: Spike doesn't emulate misaligned
  accesses by default. It is skipped in the suite.
- rv64ua `amocas*` tests are not built: the pinned GCC 14 lacks Zacas.
- Debug mode replays the session from reset for each command, so each command costs a
  full re-run up to that point. Fine for small programs; slow for very long ones.
- `--extlib` plugins and `--rbb-port` (remote bitbang) are not available in the browser.

## License

BSD-3-Clause, see [LICENSE](LICENSE). Spike, riscv-tests and emsdk keep their own
licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).
