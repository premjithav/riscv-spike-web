// Runs one Spike simulation per worker. The page compiles spike-web.wasm once
// and hands the WebAssembly.Module over, so each run only instantiates.
importScripts('spike-web.js');

const TRACE_CAP = 4000;          // trace lines forwarded to the page
let buf = [], traceShown = 0, traceTotal = 0, timer = null;

function flush() {
  timer = null;
  if (buf.length) { postMessage({ type: 'chunk', lines: buf }); buf = []; }
}
function schedule() { if (!timer) timer = setTimeout(flush, 60); }

// Spike's -l trace lines start with "core   N:"; everything else on stderr is a message.
const isTrace = (s) => s.startsWith('core ');

onmessage = async (e) => {
  const { module, elf, dtb, args } = e.data;
  const t0 = performance.now();
  let exitCode = null;
  try {
    const M = await createSpike({
      noInitialRun: true,
      instantiateWasm(imports, done) {
        WebAssembly.instantiate(module, imports).then((inst) => done(inst, module));
        return {};
      },
      print: (s) => { buf.push(['o', s]); schedule(); },
      printErr: (s) => {
        if (isTrace(s)) {
          traceTotal++;
          if (traceShown >= TRACE_CAP) return;
          traceShown++;
        }
        buf.push([isTrace(s) ? 't' : 'e', s]); schedule();
      },
      onExit: (code) => { exitCode = code; },
      onAbort: (what) => { buf.push(['e', '[aborted] ' + what]); schedule(); },
    });
    M.FS.writeFile('/sim.dtb', new Uint8Array(dtb));
    M.FS.writeFile('/prog.elf', new Uint8Array(elf));
    const ret = M.callMain(args);
    if (exitCode === null && typeof ret === 'number') exitCode = ret;
  } catch (err) {
    if (err && typeof err.status === 'number') exitCode = err.status;   // ExitStatus
    else buf.push(['e', '[error] ' + (err && err.message ? err.message : String(err))]);
  }
  if (timer) clearTimeout(timer);
  flush();
  postMessage({ type: 'done', exitCode, ms: performance.now() - t0, traceShown, traceTotal });
};
