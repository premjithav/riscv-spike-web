# Contributing

Thanks for helping. A few rules keep this project easy to maintain.

## Ground rules

1. **Never edit `third_party/`.** Spike, riscv-tests and emsdk stay pristine upstream
   checkouts so that `scripts/update-spike.sh` can move to a new Spike release at any
   time. Workarounds go in `scripts/env.sh` (compiler or linker flags, make variable
   overrides) or in the demo's JavaScript. If something can only be fixed in Spike,
   send it upstream to riscv-isa-sim.
2. **Keep `verify.sh` green.** Any change to the build must keep both the native and the
   WebAssembly builds passing the riscv-tests suite with identical `-l` traces.
3. **Scripts stay resumable.** Every step may be interrupted and re-run.

## Before opening a pull request

```bash
./scripts/build-all.sh      # builds, verifies and assembles the demo
make serve                  # check the demo in a browser: Run and Debug modes
```

Describe what you changed and paste the last lines of `verify.sh` output.

## Adding a program to the demo

Add an entry to `demo/programs.json` (`bench:` for files in `build/bench`, `test:` for
files in `build/tests/isa`), build it in `scripts/build-tests.sh` if needed, then run
`./scripts/build-demo.sh`.

## License

By contributing you agree that your contributions are licensed under the
BSD-3-Clause license in `LICENSE`.
