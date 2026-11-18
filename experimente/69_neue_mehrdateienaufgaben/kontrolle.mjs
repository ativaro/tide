// Paired sensitivity check of the process boundary, retaining the frozen task data.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {performance} from 'node:perf_hooks';
const here=path.dirname(fileURLToPath(import.meta.url));
const read=n=>JSON.parse(fs.readFileSync(path.join(here,n),'utf8'));
const json=JSON.stringify, hash=s=>createHash('sha256').update(s).digest('hex');
const tasks=read('aufgaben.json'), cases=read('prueffaelle.json'), plan=read('versuchsplan.json');
const frozen=read('fixierung.json'), original=read('messung.json');
for(const [name,expected] of Object.entries(frozen.files)) assert.equal(hash(fs.readFileSync(path.join(here,name))),expected);
assert.equal(hash(json(cases)),original.inputs_sha256);
assert.equal(fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(\S+)$/m)[1],original.environment.core);
assert.deepEqual(fs.readFileSync('/proc/net/dev','utf8').trim().split('\n').slice(2).map(l=>l.trim().split(':')[0]),['lo']);
const examples=(rows,tag)=>rows.map((r,i)=>'\nexample '+tag+i+' main\n'+json(r)+'\n').join('');
function run(program,args,input,errors=[0]) {
  const p=spawnSync(program,args,{input,encoding:'utf8',timeout:15000});
  assert(errors.includes(p.status),p.stderr);
  return JSON.parse(p.status?p.stderr:p.stdout);
}
const tide=process.env.TIDE_BIN;
const py=(mode,dir,rows)=>run(process.env.CPYTHON||'/usr/bin/python3',['-I','-B','-S',path.join(here,'cpython_kompakt.py'),mode,dir],json(rows));
function nativeRepair(entry,folder,count) {
  const {code,repair}=run(tide,['test',entry,'--diff','--explain=candidates','--pairs'],undefined,[1]);
  assert.equal(code,'E_EXAMPLE');
  const options=repair.candidates.length?repair.candidates.map(e=>[e]):repair.pair_candidates;
  const rank=edits=>edits.map(e=>{
    const bits=e.node.split(':'),name=/^\d+$/.test(bits[0])?'panel':bits.shift().split('.')[0];
    return [name,bits[0].padStart(5,'0'),bits[1].padStart(5,'0'),e.op||e.replace].join(':');
  }).sort().join('|');
  const chosen=options.toSorted((a,b)=>rank(a)<rank(b)?-1:rank(a)>rank(b)?1:0)[0]||[];
  if(!chosen.length) return [];
  const args=['edit',entry,'--base',repair.revision,'--edits',json(chosen)];
  const result=run(tide,chosen.length===1?[...args,'--write']:args);
  if(chosen.length===1) assert.equal(result.written,true);
  else {
    assert.equal(result.examples.passed,count);
    for(const f of result.files) fs.writeFileSync(path.join(folder,f.file),f.source);
  }
  return chosen;
}
function trial(task,arm) {
  const folder=fs.mkdtempSync(path.join(os.tmpdir(),'tide69-c-'));
  try {
    const native=arm==='tide',ext=native?'.tide':'.py',entry=path.join(folder,'panel'+ext);
    const pub=cases[task.id].public;
    for(const [name,source] of Object.entries(task[arm])) fs.writeFileSync(path.join(folder,name+ext),source+
      (native&&name==='panel'?examples(pub,'public_'):''));
    const start=performance.now();
    const edits=native?nativeRepair(entry,folder,pub.length):py('repair',folder,pub);
    let status='no_candidate';
    if(edits.length){
      const held=cases[task.id].hidden;
      if(native) fs.appendFileSync(entry,examples(held,'sealed_'));
      const accepted=native?run(tide,['test',entry],undefined,[0,1]).passed===pub.length+held.length
        :py('accept',folder,[...pub,...held]);
      status=accepted?'accepted':'failed_acceptance';
    }
    return {ms:performance.now()-start,status,edits};
  } finally {fs.rmSync(folder,{recursive:true,force:true});}
}
const pairs=[];
for(let round=-1;round<plan.rounds;round++){
  for(let i=0;i<tasks.length;i++) {
    const idx=(i+Math.max(0,round))%tasks.length,task=tasks[idx];
    const order=(round+idx)%2===0?['tide','python']:['python','tide'];
    const pair={round,task:task.id,first:order[0]};
    for(const arm of order) pair[arm]=trial(task,arm);
    if(round>=0) pairs.push(pair);
  }
}
const transcripts=read('protokolle.json');
for(const pair of pairs) for(const arm of ['tide','python']) {
  const expected=transcripts[pair.task][arm];
  assert.equal(pair[arm].status,expected[3].body.status);
  assert.deepEqual(pair[arm].edits,expected[2].body.edits||[]);
}
const median=vs=>{const x=vs.toSorted((a,b)=>a-b),k=Math.floor(x.length/2);return x.length%2?x[k]:(x[k-1]+x[k])/2;};
const passed=pairs.filter(p=>p.tide.status==='accepted');
const ratios=passed.map(p=>p.python.ms/p.tide.ms).sort((a,b)=>a-b);
const summary={successful_pairs:passed.length,tide_ms:median(passed.map(p=>p.tide.ms)),python_ms:median(passed.map(p=>p.python.ms)),
  paired_ratio:median(ratios),ratio_q1:ratios[Math.ceil(ratios.length*.25)-1],ratio_q3:ratios[Math.ceil(ratios.length*.75)-1],
  tide_faster_pairs:ratios.filter(x=>x>1).length};
fs.writeFileSync(path.join(here,'kontrollmessung.json'),JSON.stringify({inputs_sha256:original.inputs_sha256,summary,pairs},null,2)+'\n');
console.log(summary);
