# Updating Spike

```bash
./scripts/update-spike.sh            # latest upstream master
./scripts/update-spike.sh v1.1.0     # a tag
./scripts/update-spike.sh 1a2b3c4d   # a commit
make update                          # same as the first line
```

What it does:

1. Refuses to run if `third_party/riscv-isa-sim` has local changes.
2. Fetches the ref and checks it out in the submodule.
3. Runs `scripts/build-all.sh`. Build trees are per commit (`build/spike-<sha>/`), so the
   new version always builds from scratch and the previous build stays.
4. If the build **and** `verify.sh` pass, commits the new submodule pointer:
   `Update riscv-isa-sim to <sha> (<ref>)`.
5. If anything fails, checks the previous commit out again and keeps the failed build
   tree for inspection. Your working tree is left as it was.

After a successful update, push and (if you host the demo) let CI republish it, or run
`./scripts/build-demo.sh` and upload `demo/site/`.

## When an update fails

Look at the failing step's output:

- **Compile error in the wasm build** (`build/spike-<sha>/wasm/build.log`): usually a new
  wasm32-specific warning or a new host dependency. Fix it with a flag in `scripts/env.sh`
  (`WASM_CFLAGS`, `WASM_*_LINK`) or a configure option in `build-wasm.sh`, never by editing
  Spike. If it really needs a source change, report it upstream.
- **`verify.sh` reports a failing test on both native and wasm**: a Spike behaviour change
  or a test that needs a new option; check upstream's changelog.
- **Trace differences only on wasm**: a real porting bug. Diff the two traces:

  ```bash
  t=build/tests/isa/rv64ui-p-add
  install/native/bin/spike -l --isa=rv64gc -m256 --dtb=dtb/rv64gc.dtb $t > /tmp/n.txt 2>&1
  node dist/node/spike.js  -l --isa=rv64gc -m256 --dtb=dtb/rv64gc.dtb $t > /tmp/w.txt 2>&1
  diff /tmp/n.txt /tmp/w.txt | head
  ```

## Early warning

The CI workflow's weekly `upstream-canary` job builds and verifies the latest upstream
Spike without committing anything, so you hear about breakage before you update.
