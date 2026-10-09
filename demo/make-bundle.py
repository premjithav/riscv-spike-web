#!/usr/bin/env python3
"""Pack demo programs, per-ISA DTBs and build info into bundle.json for the browser demo."""
import argparse, base64, json, os

ap = argparse.ArgumentParser()
ap.add_argument('--programs', required=True); ap.add_argument('--tests', required=True)
ap.add_argument('--bench', required=True);    ap.add_argument('--dtb', required=True)
ap.add_argument('--isas', nargs='+', required=True)
ap.add_argument('--spike', required=True);    ap.add_argument('--emscripten', default='unknown')
ap.add_argument('--verify');                  ap.add_argument('--out', required=True)
a = ap.parse_args()

b64 = lambda p: base64.b64encode(open(p, 'rb').read()).decode()
dirs = {'test': a.tests, 'bench': a.bench}
programs = []
for p in json.load(open(a.programs)):
    kind, fname = p['src'].split(':', 1)
    path = os.path.join(dirs[kind], fname)
    programs.append(dict(group=p['group'], name=p['name'], file=fname, desc=p['desc'],
                         size=os.path.getsize(path), b64=b64(path)))
verify = json.load(open(a.verify)) if a.verify and os.path.exists(a.verify) else {}
bundle = dict(
    build=dict(spike=a.spike, emscripten=a.emscripten, verify=verify),
    programs=programs,
    dtbs={isa: b64(os.path.join(a.dtb, isa + '.dtb')) for isa in a.isas},
)
json.dump(bundle, open(a.out, 'w'))
print(f"{a.out}: {len(programs)} programs, {len(bundle['dtbs'])} DTBs, spike {a.spike}")
