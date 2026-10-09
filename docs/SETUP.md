# Setup

This guide takes a fresh Linux machine to a working native Spike, Node.js and browser
builds of Spike, a verified test run, and the browser demo.

Time and space: about 20 minutes of build time on a 2-core machine (less with more cores), and about 4 GB of disk
(Emscripten ~1.5 GB, RISC-V GCC ~1.3 GB, build trees ~1 GB).

## 1. Prerequisites

Developed and tested on **Ubuntu 22.04** and **24.04**, x86_64. Debian 12 and other Debian-based
distributions should work with the same packages; other distributions need the equivalents. macOS and Windows (except WSL2) are not covered.

System packages:

```bash
sudo apt-get update
sudo apt-get install -y build-essential git curl python3 xz-utils device-tree-compiler
```

`./scripts/setup-tools.sh --install-deps` runs the same command for you.

Network access is needed during setup for:

| Host | Used for |
|---|---|
| github.com | submodules and the xPack RISC-V GCC release |
| storage.googleapis.com | Emscripten toolchain (`emsdk install`) |

You don't need a system Node.js: the scripts use the one that comes with emsdk if `node`
is not on your `PATH`.

## 2. Get the source

```bash
git clone --recurse-submodules https://github.com/<you>/riscv-spike-web.git
cd riscv-spike-web
```

If you cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

## 3. Install the toolchains

```bash
./scripts/setup-tools.sh            # add --install-deps to also run the apt-get step above
```

This is safe to re-run; it skips anything already installed. It:

1. checks out the submodules (`third_party/riscv-isa-sim`, `riscv-tests`, `emsdk`);
2. downloads **xPack RISC-V GCC 14.2.0-3** into `tools/riscv-none-elf-gcc` (used to build
   the test programs);
3. checks for `dtc`;
4. installs and activates **Emscripten 6.0.12** inside `third_party/emsdk`.

Check it worked:

```bash
tools/riscv-none-elf-gcc/bin/riscv-none-elf-gcc --version | head -1
source third_party/emsdk/emsdk_env.sh && emcc --version | head -1
```

## 4. Build and verify

```bash
./scripts/build-all.sh
```

which runs, in order:

| Step | Produces | Measured on 2 cores |
|---|---|---|
| `build-native.sh` | `install/native/bin/spike`, `dtb/{rv64gc,rv64imac,rv64gcv}.dtb` | ~7 min |
| `build-tests.sh` | `build/tests/isa/*`, `build/bench/*.riscv` | 1 min |
| `build-wasm.sh` | `dist/node/spike.{js,wasm}`, `dist/web/spike.{js,wasm}` | ~9 min |
| `verify.sh` | `dist/verify.json`; fails if any check fails | ~1.5 min |
| `build-demo.sh` | `demo/site/` | seconds |

Every step can be interrupted and re-run; `make` picks up where it stopped.

A successful run ends with:

```
native: PASS=109 FAIL=0 (skipped: rv64ui-p-ma_data)
wasm: PASS=109 FAIL=0 (skipped: rv64ui-p-ma_data)
traces identical: 110, different: none
==> verify PASSED
```

## 5. Run things

Native and Node.js builds take the same arguments:

```bash
install/native/bin/spike --isa=rv64gc -m256 --dtb=dtb/rv64gc.dtb build/bench/dhrystone.riscv
node dist/node/spike.js  --isa=rv64gc -m256 --dtb=dtb/rv64gc.dtb build/bench/dhrystone.riscv
```

Always pass `--dtb=dtb/<isa>.dtb` to the wasm build (it can't run `dtc` itself). The hart
ISA comes from the DTB, so use the DTB that matches `--isa`.

Instruction trace and interactive debugger work as in native Spike:

```bash
node dist/node/spike.js -l --isa=rv64gc -m256 --dtb=dtb/rv64gc.dtb build/tests/isa/rv64ui-p-add | head
node dist/node/spike.js -d --isa=rv64gc -m256 --dtb=dtb/rv64gc.dtb build/bench/hello.riscv
```

Browser demo:

```bash
make serve          # python3 -m http.server -d demo/site 8080
```

Open http://localhost:8080. Serve it over HTTP; opening `index.html` from disk does not
work, because the page loads its Web Worker and wasm with `fetch`.

## Configuration

Settings are environment variables read by `scripts/env.sh`:

| Variable | Default | Meaning |
|---|---|---|
| `BUILD_ROOT` | `build` | where per-commit build trees go (`$BUILD_ROOT/spike-<sha>/`) |
| `JOBS` | `nproc` | parallel make jobs |
| `ISA` | `rv64gc` | hart ISA for the test suite |
| `DEMO_ISAS` | `rv64gc rv64imac rv64gcv` | DTBs generated for the demo's ISA menu |
| `MEM` | `256` | simulated memory in MiB |
| `RISCV_PREFIX` | `riscv-none-elf-` | cross-compiler prefix for the test programs |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `configure: error: device-tree-compiler not found` | `sudo apt-get install device-tree-compiler`, or put a static `dtc` in `tools/bin/` |
| `emsdk install` fails to download | `storage.googleapis.com` must be reachable. On a restricted network, run `third_party/emsdk/emsdk install 6.0.12` on a machine that can reach it; the install is relocatable, so you can copy `third_party/emsdk` over. |
| `emcc not found` in `build-wasm.sh` | Run `./scripts/setup-tools.sh` (or `cd third_party/emsdk && ./emsdk activate 6.0.12`). |
| `ar: ... Too many open files` | Raise the limit (`ulimit -n 65536`). On network or shared folders (virtiofs, NFS), set `BUILD_ROOT` to a local disk. |
| wasm link fails with undefined `fast_rv64i_*` symbols | An interrupted compile left a truncated object. Delete the wasm build tree (`rm -rf build/spike-*/wasm`) and re-run `build-wasm.sh`. |
| `rv64ui-p-ma_data` fails | Expected: Spike doesn't emulate misaligned accesses by default. The suite skips it. |
| Demo page shows "Could not load the simulator" | Serve over HTTP (`make serve`), not from `file://`. |
| Builds are slow on a shared or synced folder | `BUILD_ROOT=$HOME/spike-build ./scripts/build-all.sh` |

### Time-limited shells

On environments that stop long-running commands (some CI runners, sandboxed shells),
run the steps one at a time and repeat a step until it finishes; each is resumable.
