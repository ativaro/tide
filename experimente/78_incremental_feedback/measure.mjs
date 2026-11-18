// Time public CLI requests against identical atomically replaced input files.
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createInterface } from 'node:readline';
import { mkdtempSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { tmpdir, cpus, release, arch } from 'node:os';
import { fileURLToPath } from 'node:url';

const tide = resolve(process.argv[2]);
const work = mkdtempSync(join(tmpdir(), 'tide-feedback-'));
const entry = join(work, 'suite.tide');
const clients = [];
function run(command, args) {
  const result = spawnSync(command, args, {encoding: 'utf8', timeout: 30000});
  if (result.error) throw result.error;
  assert.ok([0, 1].includes(result.status), result.stderr);
  return result;
}
function fresh() {
  const {status, stdout, stderr} = run(tide, ['test', entry]);
  if (status === 0) { assert.equal(stderr, ''); return JSON.parse(stdout); }
  assert.equal(stdout, '');
  return JSON.parse(stderr);
}
function startSession() {
  const proc = spawn(tide, ['test', entry, '--incremental'], {stdio: ['pipe','pipe','inherit']});
  const lines = createInterface({input: proc.stdout})[Symbol.asyncIterator]();
  const exited = new Promise((ok, fail) => {
    proc.once('error', fail);
    proc.once('exit', (status, signal) => ok({status, signal}));
  });
  clients.push({proc, exited});
  return async request => {
    proc.stdin.write(request + '\n');
    const {value, done} = await lines.next();
    assert.equal(done, false, 'test session closed');
    return JSON.parse(value);
  };
}
function save(files) {
  for (const [name, bytes] of Object.entries(files)) {
    const path = join(work, name);
    writeFileSync(path + '.new', bytes);
    renameSync(path + '.new', path);
  }
}
const source = name => readFileSync(join(work, name), 'utf8');
function replace(text, before, after) {
  assert.ok(text.includes(before), before);
  return text.replace(before, after);
}
function scenarios() {
  const leaf = 'cursor.tide', pkg = 'vendor/measurements/1.3.0/package.tide';
  const model = 'model.tide', caller = 'import.tide';
  const cursor = source(leaf), decoder = source(pkg), original = source(model), importer = source(caller);
  const updated = replace(original, 'identifier value:t', 'identifier limit:i value:t')
    .replaceAll(') 64)', ') limit)');
  const migrateCalls = s => s.replaceAll('(identifier ', '(identifier 64 ');
  return [
    {name:'leaf', a:{[leaf]:cursor},
      b:{[leaf]:replace(cursor, '(- pos 2) (- pos 1)', '(- (- pos 1) 1) (- pos 1)')},
      red:() => ({[leaf]:replace(cursor, '(- pos 2) (- pos 1)', '(- pos 1) (- pos 1)')})},
    {name:'interface', a:{[model]:original,[caller]:importer},
      b:{[model]:migrateCalls(updated),[caller]:migrateCalls(importer)},
      red:toB => toB ? {[model]:migrateCalls(updated),[caller]:importer}
                       : {[model]:original,[caller]:migrateCalls(importer)}},
    {name:'package', a:{[pkg]:decoder},
      b:{[pkg]:replace(decoder,'decode_measurement line row','decode_measurement line (+ row 0)')},
      red:() => ({[pkg]:replace(decoder,'decode_measurement line row','decode_measurement line (+ row 1)')})}
  ];
}
function stats(values) {
  const xs = values.toSorted((a,b) => a-b);
  return {median_ms:(xs[(xs.length-1)>>1]+xs[xs.length>>1])/2, p95_ms:xs[Math.ceil(xs.length*.95)-1]};
}
try {
  const prep = fileURLToPath(new URL('prepare.sh', import.meta.url));
  assert.equal(run(prep, [work]).status, 0);
  const graph = JSON.parse(run(tide,['check',entry]).stdout);
  const test = startSession(), clean = startSession();
  const arms = {incremental:() => test('test'), full_session:() => clean('full'), fresh};
  const names = Object.keys(arms);
  const orders = [[0,1,2],[1,2,0],[2,0,1],[2,1,0],[0,2,1],[1,0,2]];
  const affinity = readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(.+)$/m)[1];
  const output = {tool:graph.tool, revision:graph.revision, kernel:release(), arch:arch(), cpu:cpus()[0].model,
    affinity, modules:graph.modules.length+1,
    functions:Object.keys(graph.definitions).length, examples:graph.examples,
    warmup_blocks:6, measured_blocks:36, scenarios:{}};
  for (const scenario of scenarios()) {
    save(scenario.a);
    for (const name of names) assert.equal((await arms[name]()).passed, graph.examples);
    const rows = [];
    let workCounts;
    const errors = {};
    for (let block=0; block<42; block++) {
      const toB = block%2 === 0;
      const red = scenario.red(toB), green = toB ? scenario.b : scenario.a;
      save(red);
      const diagnostic = fresh();
      assert.ok(diagnostic.code && diagnostic.file && diagnostic.line);
      for (const name of ['incremental','full_session']) assert.deepEqual(await arms[name](), diagnostic);
      const direction = toB ? 'a_to_b' : 'b_to_a';
      const normalized = {...diagnostic,file:diagnostic.file.replace(work+'/', '')};
      if (errors[direction]) assert.deepEqual(normalized,errors[direction]);
      errors[direction] = normalized;
      const times = {};
      for (const index of orders[block % orders.length]) {
        const name = names[index];
        save(red);
        const start = process.hrtime.bigint();
        save(green);
        const reply = await arms[name]();
        assert.equal(reply.passed, graph.examples);
        times[name] = Number(process.hrtime.bigint()-start)/1e6;
        if (name === 'incremental') {
          assert.ok(reply.checked_functions > 0 && reply.checked_functions < output.functions);
          assert.ok(reply.executed_examples > 0 && reply.executed_examples < graph.examples);
          const counts = [reply.checked_functions, reply.executed_examples];
          if (workCounts) assert.deepEqual(counts, workCounts);
          workCounts = counts;
        } else if (name === 'full_session') {
          assert.equal(reply.checked_functions, output.functions);
          assert.equal(reply.executed_examples, graph.examples);
        }
      }
      if (block >= 6) rows.push(times);
    }
    output.scenarios[scenario.name] = {checked_functions:workCounts[0],executed_examples:workCounts[1],
      red_diagnostics:errors,summary:Object.fromEntries(names.map(n => [n,stats(rows.map(r=>r[n]))])),samples_ms:rows};
    save(scenario.a);
  }
  console.log(JSON.stringify(output,null,2));
} finally {
  for (const {proc} of clients) proc.stdin.end();
  for (const {exited} of clients) assert.deepEqual(await exited,{status:0,signal:null});
  rmSync(work,{recursive:true,force:true});
}
