# Third-party components

This repository contains only build scripts, a demo page and documentation. The
components below are pulled in as git submodules or downloaded by
`scripts/setup-tools.sh`; each keeps its own license. They are not modified.

| Component | Where | License | Upstream |
|---|---|---|---|
| Spike (riscv-isa-sim) | `third_party/riscv-isa-sim` | BSD-3-Clause | https://github.com/riscv-software-src/riscv-isa-sim |
| riscv-tests | `third_party/riscv-tests` | BSD-3-Clause | https://github.com/riscv-software-src/riscv-tests |
| Emscripten SDK (emsdk) | `third_party/emsdk` | MIT | https://github.com/emscripten-core/emsdk |
| xPack GNU RISC-V Embedded GCC | `tools/riscv-none-elf-gcc` (downloaded, git-ignored) | GPL-3.0 with GCC runtime exception; see the package | https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack |
| Device Tree Compiler (dtc) | system package `device-tree-compiler` | GPL-2.0-or-later / BSD-2-Clause (libfdt) | https://git.kernel.org/pub/scm/utils/dtc/dtc.git |

## Redistributing built artifacts

The browser demo in `demo/site/` contains binaries built from the components above:

- `spike-web.wasm` / `spike-web.js`: Spike compiled with Emscripten. When you publish
  them, ship Spike's BSD-3-Clause license text with them (Emscripten's runtime is MIT).
- `bundle.json`: RISC-V ELF programs built from riscv-tests (BSD-3-Clause), and
  `demo/src/hello.c` from this repository.

`scripts/build-demo.sh` copies these license texts into `demo/site/licenses/`, so a
published demo carries them.
