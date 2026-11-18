// External timing and database verification. TIDE and CPython run as separate processes.
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const [phase, workspace] = process.argv.slice(2);
assert.ok(['pre', 'post', 'compare', 'warm', 'source'].includes(phase));
const comparison = ['compare', 'source', 'warm'].includes(phase);
const work = path.resolve(workspace), file = path.join(work, 'input.json'), db = path.join(work, 'timed.db');
const stage4 = path.resolve(here, '../73_bestellimport');
const frozen = JSON.parse(fs.readFileSync(path.join(stage4, 'compare.json'))).summary;
const sha = x => createHash('sha256').update(x).digest('hex');
function run(cmd, args) {
  const r = spawnSync(cmd, args, {encoding: 'utf8'});
  assert.ifError(r.error);
  assert.equal(r.signal, null);
  return r;
}
function checked(cmd, args) {
  const r = run(cmd, args);
  assert.equal(r.status, 0, r.stderr);
  return r.stdout.trim();
}
const timer =
    'zmodload zsh/datetime; TIMEFMT="PEAK_KIB %M"; t=$EPOCHREALTIME; time "$@"; r=$?; printf "ELAPSED_MS %.6f\\n" $((1000*(EPOCHREALTIME-t))) >&2; exit $r';
function timed(command) {
  const r = run('/usr/bin/zsh', ['-fc', timer, '--', ...command]);
  const m = r.stderr.match(/PEAK_KIB (\d+)\nELAPSED_MS ([\d.]+)\n$/);
  assert.ok(m, r.stderr);
  return {
    status: r.status,
    stdout: r.stdout.trim(),
    stderr: r.stderr.slice(0, m.index).trim(),
    ms: Number(m[2]),
    peak_kib: Number(m[1])
  };
}
function fixture(n, bad, unicode) {
  const sku = unicode ? 'Pièce猫' : 'Part';
  const events = [], lines = [], ledger = [];
  for (let i = 0; i < n / 4; i++) {
    const line = String(i).padStart(4, '0');
    const order = {id: 'O' + line, kind: 'order', order: 'PO', line, qty: 3, sku, unit_cents: 125};
    const cancel = {id: 'C' + line, kind: 'cancel', order: 'PO', line, qty: 2};
    events.push(order, {...order, memo: 'redelivery'}, cancel, {...cancel, memo: 'redelivery'});
    lines.push(['ACME', 'PO', line, sku, 3, 1, 125]);
    for (const e of [order, cancel])
      ledger.push(['ACME', e.id, e.kind, 'PO', line, e.qty, e.sku ?? '', e.unit_cents ?? 0]);
  }
  if (bad)
    events[n - 1] = {...events[n - 1], id: 'over', qty: 3};
  ledger.sort((a, b) => a[1] < b[1] ? -1 : 1);
  return {data: JSON.stringify({supplier: 'ACME', events}), lines, ledger};
}
function rows(query) {
  const data = checked('sqlite3', ['-batch', '-json', db, query]);
  return JSON.parse(data || '[]').map(Object.values);
}
function verifyDb(f, bad) {
  if (bad)
    assert.deepEqual(rows('SELECT name FROM sqlite_master WHERE type=\'table\''), []);
  else {
    assert.deepEqual(
        rows('SELECT supplier,ord,line,sku,original,outstanding,cents FROM positions ORDER BY line'),
        f.lines);
    assert.deepEqual(
        rows('SELECT supplier,id,kind,ord,line,qty,sku,cents FROM events ORDER BY id'), f.ledger);
  }
}
const median = xs => {
  const s = xs.toSorted((a, b) => a - b);
  return (s[(s.length - 1) >> 1] + s[s.length >> 1]) / 2;
};
const probe = ['startup', 'read_size', 'utf8_size', 'decode_size', 'checked_quantity', 'main'];
const arms = comparison ? ['pre', 'python', 'post'] : probe;
const standard = [['mixed8', 8], ['mixed1000', 1000]];
const workloads = {
  compare: [['startup', 0], ['empty', 0], ...standard, ['unicode1000', 1000], ['rollback1000', 1000]],
  warm: [['mixed8', 8], ['mixed256', 256], ['mixed1000', 1000]],
}[phase] ?? standard;
const samples = [], summary = {}, failures = {};
const bytecode = path.join(work, 'reference.pyc');
if (phase === 'compare' && !fs.existsSync(bytecode))
  checked('python3', [
    '-c', 'import py_compile,sys; py_compile.compile(sys.argv[1],cfile=sys.argv[2],doraise=True)',
    path.join(stage4, 'cpython_import.py'), bytecode
  ]);
function command(arm, target) {
  if (arm === 'python') {
    if (target === 'startup') return ['python3', '-c', 'import json, sqlite3, sys; print(0)'];
    const script = phase === 'source' ? path.join(stage4, 'cpython_import.py') : bytecode;
    return ['python3', script, 'import', db, file];
  }
  const binary = path.join(work, comparison ? arm : phase, target);
  if (target === 'startup') return [binary];
  const read = ['--read', 'input=' + file];
  if (target !== 'main') return [binary, ...read];
  const grants = ['--db', 'db=' + db, ...read];
  if (phase === 'source') {
    const install = arm === 'pre' ? 'before' : 'after';
    return [path.join(work, install, 'usr/local/bin/tide'), 'run', 'apps/orders/import.tide', ...grants];
  }
  return [binary, ...grants];
}
const services = phase === 'warm' ? await (await import('./warm.mjs')).openServices(work, db) : null;
try {
  for (const [name, n] of workloads) {
    const bad = name === 'rollback1000', f = fixture(n, bad, name === 'unicode1000'),
          bytes = Buffer.byteLength(f.data);
    fs.writeFileSync(file, f.data);
    if (frozen[name])
      assert.equal(sha(f.data), frozen[name].sha256);
    const diagnostics = {};
    for (let b = -1; b < 12; b++) {
      const seq = Math.floor((b + 1) / arms.length) % 2 ? [...arms].reverse() : arms;
      for (let j = 0; j < seq.length; j++) {
        const arm = seq[(j + b + 1) % seq.length];
        const target = comparison ? (name === 'startup' ? 'startup' : 'main') : arm;
        fs.rmSync(db, {force: true});
        const r = services ? await services.measure(arm, f.data) : timed(command(arm, target));
        if (services && r.status !== 0 && n === 1000 && arm !== 'python') {
          assert.equal(r.http_status, 500);
          assert.equal(r.stdout, 'Request failed');
          verifyDb(f, true);
          failures[name] ??= {};
          failures[name][arm] = {http_status: r.http_status, body: r.stdout, database_tables: 0};
          if (b >= 0)
            samples.push({name, block: b, arm, accepted: false, ms: r.ms, peak_kib: r.peak_kib});
          continue;
        }
        if (bad) {
          assert.equal(r.status, 1);
          assert.equal(r.stdout, '');
          const d = JSON.parse(r.stderr);
          assert.equal(d.code, 'E_DATA');
          assert.equal(d.reason, 'over_cancel');
          assert.equal(d.issue?.path ?? d.path, '/events/999/qty');
          assert.equal(d.input_line, 999);
          diagnostics[arm] = d;
        } else {
          assert.equal(r.status, 0, [name, arm, r.stdout, r.stderr].join(' '));
          assert.equal(r.stderr, '');
          const expected = {
            startup: 0,
            read_size: bytes,
            utf8_size: f.data.length,
            decode_size: n,
            checked_quantity: n * 2.5,
            main: {applied: n / 2, duplicates: n / 2}
          };
          assert.deepEqual(JSON.parse(r.stdout), expected[target]);
        }
        if (target === 'main')
          verifyDb(f, bad);
        if (b >= 0)
          samples.push({name, block: b, arm, ms: r.ms, peak_kib: r.peak_kib});
      }
    }
    if (bad) {
      assert.deepEqual(diagnostics.pre, diagnostics.post);
      failures[name] = diagnostics;
    }
    const series = (arm, k) =>
        samples.filter(r => r.name === name && r.arm === arm && r.accepted !== false).map(r => r[k]);
    const paired = (a, b, op) => median(series(a, 'ms').map((v, i) => op(v, series(b, 'ms')[i])));
    summary[name] = {
      bytes,
      sha256: sha(f.data),
      arms: Object.fromEntries(
          arms.filter(a => series(a, 'ms').length)
              .map(a => [a, {ms: median(series(a, 'ms')), peak_kib: median(series(a, 'peak_kib'))}]))
    };
    if (comparison && !failures[name]?.pre?.http_status)
      summary[name].paired = {
        before_over_after: paired('pre', 'post', (a, b) => a / b),
        python_over_after: paired('python', 'post', (a, b) => a / b)
      };
    else if (!comparison)
      summary[name].increment_ms = Object.fromEntries(probe.map(
          (a, i) => [a, i === 0 ? median(series(a, 'ms')) : paired(a, probe[i - 1], (x, y) => x - y)]));
  }
} finally {
  if (services)
    await services.close();
}
const binaries = {
  warm: ['pre/service', 'post/service'],
  compare: ['pre/main', 'post/main', 'pre/startup', 'post/startup'],
  source: ['before/usr/local/lib/tide/bin/checker', 'after/usr/local/lib/tide/bin/checker']
}[phase] ?? probe.map(target => phase + '/' + target);
const info = {
  cpu: os.cpus()[0].model,
  kernel: os.release(),
  affinity: fs.readFileSync('/proc/self/status', 'utf8').match(/^Cpus_allowed_list:\s*(.*)$/m)[1],
  node: process.version,
  compiler: checked('c++', ['-dumpfullversion']),
  sqlite_cli: checked('sqlite3', ['--version']),
  python_sqlite:
      checked('python3', ['-c', 'import sys, sqlite3;print(sys.version.split()[0], sqlite3.sqlite_version)']),
  filesystem: checked('stat', ['-f', '-c', '%T', work]),
  python_reference_sha256: sha(fs.readFileSync(path.join(stage4, 'cpython_import.py'))),
  binaries: Object.fromEntries(binaries.map(a => [a, sha(fs.readFileSync(path.join(work, a)))]))
};
fs.writeFileSync(
    path.join(work, phase + '.json'), JSON.stringify({info, summary, failures, samples}, null, 2) + '\n');
console.log(JSON.stringify(summary, null, 2));
