// Runs one Spike simulation per worker. The page compiles spike-web.wasm once
// and hands the WebAssembly.Module over, so each run only instantiates.
//
// Debug mode: Spike's interactive debugger (-d) reads commands from stdin with a
// blocking read(). A page cannot block on user input, so the page replays the
// whole session instead: every new command re-runs the program from reset with
// the full command history on stdin, followed by "q". Spike is deterministic,
// so the replayed transcript is identical up to the new command.
importScripts('spike-web.js');

const TRACE_CAP = 4000;          // trace lines forwarded in Run mode
const DEBUG_LINE_CAP = 20000;    // transcript lines forwarded in Debug mode
let buf = [], traceShown = 0, traceTotal = 0, lineCount = 0, cap = TRACE_CAP, debug = false, timer = null;

function flush() {
  timer = null;
  if (buf.length) { postMessage({ type: 'chunk', lines: buf }); buf = []; }
}
function schedule() { if (!timer) timer = setTimeout(flush, 60); }

// Spike's trace lines start with "core   N:"; everything else on stderr is a message.
const isTrace = (s) => s.startsWith('core ');

function push(kind, s) {
  if (debug) {
    // Drop the debugger's own prompt and keystroke echo; the page prints the command.
    if (kind !== 'o' && s.includes('(spike) ')) return;
    if (++lineCount > DEBUG_LINE_CAP) { if (kind === 't') traceTotal++; return; }
    if (kind === 't') { traceTotal++; traceShown++; }
  } else if (kind === 't') {
    traceTotal++;
    if (traceShown >= cap) return;
    traceShown++;
  }
  buf.push([kind, s]); schedule();
}

onmessage = async (e) => {
  const { module, elf, dtb, args, input } = e.data;
  debug = typeof input === 'string';
  const t0 = performance.now();
  let exitCode = null, pos = 0, cmdIndex = 0;
  try {
    const M = await createSpike({
      noInitialRun: true,
      instantiateWasm(imports, done) {
        WebAssembly.instantiate(module, imports).then((inst) => done(inst, module));
        return {};
      },
      print: (s) => push('o', s),
      printErr: (s) => push(isTrace(s) ? 't' : 'e', s),
      stdin: () => {
        if (!debug || pos >= input.length) return null;
        if (pos === 0 || input[pos - 1] === '\n') {
          const end = input.indexOf('\n', pos);
          buf.push(['c', input.slice(pos, end < 0 ? undefined : end), cmdIndex++]);
        }
        return input.charCodeAt(pos++);
      },
      onExit: (code) => { exitCode = code; },
      onAbort: (what) => push('e', '[aborted] ' + what),
    });
    if (debug) {
      // Spike reads debugger input from fd 2 (a terminal is readable on stderr);
      // Emscripten's stderr has no input side, so route those reads to stdin.
      const stdinStream = M.FS.getStream(0), fsRead = M.FS.read;
      M.FS.read = function (stream, ...rest) { return fsRead.call(this, stream.fd === 2 ? stdinStream : stream, ...rest); };
    }
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
  postMessage({ type: 'done', exitCode, ms: performance.now() - t0, traceShown, traceTotal,
    linesDropped: Math.max(0, lineCount - DEBUG_LINE_CAP), commandsRead: cmdIndex });
};
