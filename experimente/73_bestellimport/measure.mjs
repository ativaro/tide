// External timing driver. All TIDE application logic runs in the measured executable.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const [phase, bin, dir] = process.argv.slice(2);
assert.ok(['profile', 'isolate', 'compare', 'source'].includes(phase));
const reference = path.join(here, 'cpython_import.py');
const hash = data => createHash('sha256').update(data).digest('hex');
const call = (cmd, args) => spawnSync(cmd, args, { encoding: 'utf8', env: {...process.env, PYTHONDONTWRITEBYTECODE:'1'} });
const db = path.join(dir, 'orders.db'), input = path.join(dir, 'input.json');
const bytecode = path.join(dir, 'cpython_import.pyc');
if (phase === 'compare') {
  const prep = call('python3',['-c','import py_compile,sys; py_compile.compile(sys.argv[1],cfile=sys.argv[2],doraise=True)',reference,bytecode]);
  assert.equal(prep.status,0,prep.stderr);
}
function sqlite(sql) {
  const r = call('sqlite3', ['-batch', '-json', db, sql]);
  assert.equal(r.status, 0, r.stderr);
  return JSON.parse(r.stdout || '[]');
}
function state() {
  if (!sqlite("SELECT name FROM sqlite_master WHERE name='events'").length) {
    assert.equal(sqlite("SELECT name FROM sqlite_master WHERE type='table'").length, 0);
    return [[], []];
  }
  return [sqlite('SELECT supplier,ord,line,sku,original,outstanding,cents FROM positions ORDER BY line'),
          sqlite('SELECT supplier,id,kind,ord,line,qty,sku,cents FROM events ORDER BY id')];
}
function fixture(n, bad) {
  const events = [], positions = [], ledger = [];
  for (let i = 0; i < n / 4; ++i) {
    const line = String(i).padStart(4,'0');
    const order = {id:'O'+line, kind:'order', order:'PO', line, qty:3, sku:'Part', unit_cents:125};
    const cancel = {id:'C'+line, kind:'cancel', order:'PO', line, qty:2};
    events.push(order, {...order, memo:'redelivery'}, cancel, {...cancel, memo:'redelivery'});
    positions.push({supplier:'ACME',ord:'PO',line,sku:'Part',original:3,outstanding:1,cents:125});
    for (const e of [order,cancel])
      ledger.push({supplier:'ACME',id:e.id,kind:e.kind,ord:'PO',line,qty:e.qty,sku:e.sku ?? '',cents:e.unit_cents ?? 0});
  }
  if (bad) events[n - 1] = {...events[n - 1], id:'over', qty:3};
  ledger.sort((a,b) => a.id < b.id ? -1 : 1);
  return {data:JSON.stringify({supplier:'ACME',events}),rows:bad ? [[],[]] : [positions,ledger]};
}
const median = a => {
  const s = a.toSorted((x,y)=>x-y);
  return (s[(s.length-1)>>1] + s[s.length>>1])/2;
};
const raw = [], summary = {};
const arms = phase === 'profile' ? ['read_pre','count_pre','initial'] : phase === 'isolate' ? ['initial','db_only','final'] : ['initial','python_before','final','python_after'];
const settings = !['compare','source'].includes(phase) ? [['mixed1000',1000,false]] :
  [['mixed8',8,false],['mixed1000',1000,false],['replay1000',1000,false],['rollback1000',1000,true]];
for (const [name,n,bad] of settings) {
  const f = fixture(n,bad);
  fs.writeFileSync(input,f.data);
  const replay = name === 'replay1000';
  const receipt = {applied:replay ? 0 : n/2,duplicates:replay ? n : n/2};
  if (replay) {
    fs.rmSync(db,{force:true});
    const seed = call('python3',[reference,'import',db,input]);
    assert.equal(seed.status,0,seed.stderr);
    assert.deepEqual(state(),f.rows);
    fs.copyFileSync(db,db+'.seed');
  }
  for (let block = -1; block < 12; ++block) {
    // A balanced Latin square rotates start positions and reverses alternating cycles.
    const sequence = Math.floor((block+1)/arms.length)%2 ? [...arms].reverse() : [...arms];
    for (let j=0;j<arms.length;++j) {
      const arm = sequence[(j+block+1)%arms.length];
      fs.rmSync(db,{force:true});
      if (replay) fs.copyFileSync(db+'.seed',db);
      const probe = ['read_pre','count_pre'].includes(arm);
      const py = arm.startsWith('python');
      const interpreted = phase === 'source' && !py;
      const src = arm === 'initial' ? '/before-orders/import.tide' : '/orders/import.tide';
      const cmd = py ? 'python3' : interpreted ? (arm === 'initial' ? '/opt/before/bin/tide' : '/opt/tide/bin/tide') : path.join(bin,arm);
      const args = py ? [phase === 'compare' ? bytecode : reference,'import',db,input] :
        interpreted ? ['run',src,'--db','db='+db,'--read','input='+input] :
        [...(probe ? [] : ['--db','db='+db]),'--read','input='+input];
      const start = process.hrtime.bigint();
      const r = call(cmd,args);
      const ms = Number(process.hrtime.bigint()-start)/1e6;
      if (probe) {
        assert.equal(r.status,0,r.stderr);
        assert.equal(JSON.parse(r.stdout),arm==='read_pre'?Buffer.byteLength(f.data):n);
      } else {
        if (bad) {
          assert.notEqual(r.status,0);
          const err = r.stdout + r.stderr;
          assert.ok(err.includes('over_cancel') && err.includes('/events/999/qty'),err);
        } else {
          assert.equal(r.status,0,r.stderr + r.stdout);
          assert.deepEqual(JSON.parse(r.stdout),receipt);
        }
        assert.deepEqual(state(),f.rows);
      }
      if (block>=0) raw.push({name,block,arm,ms});
    }
  }
  const times = Object.fromEntries(arms.map(arm=>[arm,raw.filter(r=>r.name===name && r.arm===arm).map(r=>r.ms)]));
  summary[name]={bytes:Buffer.byteLength(f.data),sha256:hash(f.data),median_ms:Object.fromEntries(arms.map(a=>[a,median(times[a])]))};
  const paired = (a,b,fn) => median(times[a].map((x,i)=>fn(x,times[b][i])));
  if (phase==='profile') summary[name].phase_ms = {read_and_start:median(times.read_pre),decode:paired('count_pre','read_pre',(a,b)=>a-b),apply_and_commit:paired('initial','count_pre',(a,b)=>a-b)};
  else if (['compare','source'].includes(phase)) summary[name].paired_ratio = {tide_before_over_after:paired('initial','final',(a,b)=>a/b),python_after_over_tide_after:paired('python_after','final',(a,b)=>a/b)};
}
const info = {cpu:os.cpus()[0].model,kernel:os.release(),affinity:fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(.*)$/m)[1],
 python:call('python3',['-c','import sqlite3,sys; print(sys.version.split()[0],sqlite3.sqlite_version)']).stdout.trim(),
 sqlite_cli:call('sqlite3',['--version']).stdout.trim(),filesystem:call('stat',['-f','-c','%T',dir]).stdout.trim(),
 binaries:Object.fromEntries(arms.filter(a=>!a.startsWith('python')).map(a=>[a,hash(fs.readFileSync(path.join(bin,a)))])),reference:hash(fs.readFileSync(reference))};
if (phase === 'source') {
  delete info.binaries;
  info.checkers = Object.fromEntries(['/opt/before','/opt/tide'].map(p=>[p,hash(fs.readFileSync(p+'/lib/tide/bin/checker'))]));
  info.sources = Object.fromEntries(['/before-orders','/orders'].flatMap(p=>['import','store','model'].map(f=>[p+'/'+f,hash(fs.readFileSync(p+'/'+f+'.tide'))])));
}
fs.writeFileSync(path.join(dir,phase+'.json'),JSON.stringify({info,summary,raw},null,2)+'\n');
console.log(JSON.stringify(summary,null,2));
