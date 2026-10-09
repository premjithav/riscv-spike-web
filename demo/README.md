# Browser demo

A single static page that runs Spike (WebAssembly) in a Web Worker.

```
demo/web/index.html   page: program list, Run/Debug modes, console
demo/web/worker.js    runs one simulation per worker
demo/src/hello.c      the "hello" program
demo/programs.json    which programs go into bundle.json
demo/make-bundle.py   packs programs, DTBs and build info into bundle.json
```

## Build and run locally

```bash
./scripts/build-all.sh        # or, if Spike is already built: ./scripts/build-demo.sh
make serve                    # http://localhost:8080
```

`build-demo.sh` assembles `demo/site/`:

| File | From |
|---|---|
| `index.html`, `worker.js` | `demo/web/` |
| `spike-web.js`, `spike-web.wasm` | `dist/web/` |
| `bundle.json` | programs (`build/bench`, `build/tests/isa`), `dtb/*.dtb`, build info |
| `licenses/` | license texts of this project, Spike, riscv-tests, emsdk |

Serve `demo/site/` over HTTP; it doesn't work from `file://`.

## Host it

`demo/site/` is plain static files. Any static host works, as long as `.wasm` is served
as `application/wasm` (if not, the page falls back to a slower compile path, but still
works). No special headers are needed.

### GitHub Pages

The workflow in `.github/workflows/ci.yml` builds and publishes `demo/site/` on every push
to `main`. Enable it once:

1. On GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Push to `main`. The site appears at `https://<user>.github.io/riscv-spike-web/`.

## Add a program

1. Put the ELF in `build/bench/` (or build it in `scripts/build-tests.sh`).
2. Add an entry to `demo/programs.json`:
   ```json
   {"group": "Benchmarks", "name": "mytest", "src": "bench:mytest.riscv", "desc": "What it does."}
   ```
3. `./scripts/build-demo.sh`

Programs must be bare-metal RV64, linked at `0x80000000`, and exit through HTIF
`tohost`. To print, link against riscv-tests' `benchmarks/common` (`printf` over HTIF),
as `hello.c` does.
