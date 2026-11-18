// External comparison driver. The TIDE scenario defines the actions and expectations.
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const [,bins,dir] = process.argv.slice(2);
const study = path.dirname(fileURLToPath(import.meta.url));
const cli = '/opt/tide/bin/tide';
const run = (cmd,args) => spawnSync(cmd,args,{encoding:'utf8'});
function success(result) {
  assert.equal(result.status,0,result.stderr + result.stdout);
  return JSON.parse(result.stdout);
}
function fixture(input) {
  if (!input.startsWith('fixture:')) return input;
  if (input === 'fixture:invalid-utf8') return Buffer.from([255]);
  if (input === 'fixture:oversize') return Buffer.alloc(4194305,32);
  assert.ok(['fixture:1000','fixture:1001'].includes(input));
  const events = Array.from({length:Number(input.slice(8))},(_,i) => ({
    id:String(i).padEnd(63,'x'),kind:'order',order:'PO',line:String(i),sku:'é'.repeat(32),qty:1,unit_cents:125
  }));
  return JSON.stringify({supplier:'boundary',events});
}
const steps = success(run(cli,['run',path.join(study,'restart_cases.tide')]));
const results = {};
for (const arm of ['run','initial','final','python']) {
  const db = path.join(dir,arm+'-accept.db'), input = path.join(dir,'accept.json');
  fs.rmSync(db,{force:true});
  const snapshot = () => {
    const r = run('sqlite3',[db,'.dump']);
    assert.equal(r.status,0,r.stderr);
    return r.stdout;
  };
  const checks = [];
  for (const step of steps) {
    const expected = JSON.parse(step.expected);
    const previous = expected.error ? snapshot() : null;
    const lookup = step.operation === 'position', v1 = step.operation === 'v1';
    const key = lookup ? JSON.parse(step.input) : [];
    if (!lookup) fs.writeFileSync(input,fixture(step.input));
    let r;
    if (arm === 'python' && !v1) {
      r = run('python3',['-B',path.join(study,'cpython_import.py'),step.operation,db,...(lookup ? key : [input])]);
    } else {
      const interpreted = v1 || arm === 'run';
      const entry = v1 ? '/v1/v1.tide' : '/orders/import.tide';
      const [supplier,order,line] = key;
      r = run(interpreted ? cli : path.join(bins,lookup ? 'position' : arm),[
        ...(interpreted ? ['run',entry,...(lookup ? ['--call','position'] : v1 ? ['--call','orders_only'] : [])] : []),
        '--db','db='+db,...(lookup ? ['--inputs',JSON.stringify({supplier,order,line})] : ['--read','input='+input])
      ]);
    }
    if (expected.error) {
      assert.equal(r.status,1,step.name + ': ' + r.stdout + r.stderr);
      const actual = JSON.parse(r.stderr);
      for (const [field,value] of Object.entries(expected.error))
        assert.equal(field === 'path' ? (actual.issue?.path ?? actual.path) : actual[field],value,step.name);
      assert.equal(snapshot(),previous,step.name);
    } else {
      assert.deepEqual(success(r),expected,step.name);
    }
    checks.push(step.name);
  }
  results[arm] = checks;
}
results.tide_examples = success(run(cli,['test','/orders/checks.tide'])).passed;
fs.writeFileSync(path.join(dir,'acceptance.json'),JSON.stringify(results,null,2)+'\n');
console.log(Object.fromEntries(Object.entries(results).map(([k,v])=>[k,Array.isArray(v)?v.length:v])));
