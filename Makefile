# SPDX-License-Identifier: BSD-3-Clause
# Convenience targets; the real work is in scripts/.
PORT ?= 8080

.PHONY: help setup all native tests wasm verify demo serve update clean
help:
	@echo "make setup    install toolchains (scripts/setup-tools.sh)"
	@echo "make all      build native + wasm Spike, tests, verify, demo"
	@echo "make verify   run the native-vs-wasm verification gate"
	@echo "make serve    serve the demo on http://localhost:$(PORT)"
	@echo "make update   update Spike to upstream master (build, verify, commit or roll back)"
	@echo "make clean    remove build outputs (keeps tools/ and emsdk)"

setup:  ; ./scripts/setup-tools.sh
all:    ; ./scripts/build-all.sh
native: ; ./scripts/build-native.sh
tests:  ; ./scripts/build-tests.sh
wasm:   ; ./scripts/build-wasm.sh
verify: ; ./scripts/verify.sh
demo:   ; ./scripts/build-demo.sh
serve:  ; python3 -m http.server -d demo/site $(PORT)
update: ; ./scripts/update-spike.sh
clean:  ; rm -rf build install dist dtb demo/site logs
