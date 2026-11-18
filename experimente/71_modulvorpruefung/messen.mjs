import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {performance} from 'node:perf_hooks';

const here=path.dirname(fileURLToPath(import.meta.url));
const previous='../70_strukturelle_reparatur/';
const read=f=>JSON.parse(fs.readFileSync(path.join(here,f),'utf8'));
const save=(f,value)=>fs.writeFileSync(path.join(here,f),JSON.stringify(value,null,2)+'\n');
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const plan=read('versuchsplan.json'), tasks=read(previous+'aufgaben.json'), data=read('prueffaelle.json');
const prior=read(previous+'messung.json'), oldLogs=read(previous+'protokolle.json');
const bin=process.env.TIDE_BIN, python=process.env.CPYTHON||'/usr/bin/python3';
assert(bin && path.isAbsolute(bin),'TIDE_BIN must refer to an installed CLI');
const backend=path.dirname(fs.realpathSync(bin));
const builds=Object.fromEntries(['checker','editor','inspector'].map(f=>[f,sha(fs.readFileSync(path.join(backend,f)))]));
assert.equal(builds.inspector,prior.environment.builds.after);
assert.equal(sha(JSON.stringify(data)),prior.inputs_sha256);
const arms=['tide_before','python_before','tide_after','python_after'];
const orders=[[0,1,3,2],[1,2,0,3],[2,3,1,0],[3,0,2,1]];
const files=['versuchsplan.json','messen.mjs','cpython_modul.py','prueffaelle.json',
  ...['aufgaben.json','abnahme.tide','messung.json','protokolle.json','cpython_suche.py','auswerten.mjs'].map(f=>previous+f),
  '../60_reparaturzeit/cpython_comparison.py','../55_knotenreparatur/cpython_ast.py',
  '../../native/bootstrap/explain.tide','../../tide'];
const hashes=Object.fromEntries(files.map(f=>[f,sha(fs.readFileSync(path.join(here,f)))]));
function cmd(exe,args,input,allowed=[0]) {
  const p=spawnSync(exe,args,{input:input===undefined?undefined:JSON.stringify(input),encoding:'utf8',timeout:15000});
  if(p.error) throw p.error;
  assert(allowed.includes(p.status),[exe,...args.slice(0,3),p.status,p.stdout,p.stderr].join(' '));
  return p;
}
function py(mode,dir,target,rows){
  return JSON.parse(cmd(python,['-I','-B','-S',path.join(here,'cpython_modul.py'),mode,dir,target],rows).stdout);
}
function examples(target,rows,tag){
  return rows.map((r,i)=>'\nexample '+tag+'_'+i+' '+target+'\n'+JSON.stringify(r)+'\n').join('');
}
function sortKey(edits){
  return edits.map(e=>{
    const p=e.node.split(':');
    const name=/^\d+$/.test(p[0])?'panel':p.shift().split('.')[0];
    return [name,p[0].padStart(5,'0'),p[1].padStart(5,'0'),e.op||e.replace].join(':');
  }).sort().join('|');
}
function nativeRepair(entry,dir,n){
  const report=JSON.parse(cmd(bin,['test',entry,'--diff','--explain=candidates','--pairs'],undefined,[1]).stderr);
  assert.equal(report.code,'E_EXAMPLE');
  const r=report.repair;
  assert(r.execution.complete);
  const options=r.candidates.length?r.candidates.map(e=>[e]):r.pair_candidates;
  const candidates=options.toSorted((a,b)=>sortKey(a)<sortKey(b)?-1:sortKey(a)>sortKey(b)?1:0);
  const edits=candidates[0]||[];
  if(edits.length){
    const args=['edit',entry,'--base',r.revision,'--edits',JSON.stringify(edits)];
    const patch=JSON.parse(cmd(bin,edits.length===1?[...args,'--write']:args).stdout);
    assert.equal(patch.examples.passed,n);
    if(edits.length===1) assert(patch.written);
    else {
      assert.equal(new Set(patch.files.map(f=>f.file)).size,2);
      for(const f of patch.files){
        assert.equal(f.file,path.basename(f.file));
        fs.writeFileSync(path.join(dir,f.file),f.source);
      }
    }
  }
  return {inputs:r.inputs,actual:report.actual,candidates,edits,tested:[r.candidate_checks.tested,r.pair_checks.tested],
    truncated:[r.candidate_checks.truncated,r.pair_checks.truncated]};
}
function trial(task,arm,archive=false){
  const [language,mode]=arm.split('_'), native=language==='tide', direct=mode==='after';
  const ext=native?'.tide':'.py', dir=fs.mkdtempSync(path.join(os.tmpdir(),'tide71-'));
  const rows=data[task.id], fn=plan.route_targets[task.id], entry=path.join(dir,'panel'+ext), route=path.join(dir,'route'+ext);
  try {
    for(const [name,source] of Object.entries(task[language])) fs.writeFileSync(path.join(dir,name+ext),source);
    if(native){
      fs.appendFileSync(entry,examples('main',rows.public,'public'));
      if(direct) fs.appendFileSync(route,examples(fn,rows.public,'direct'));
    }
    const start=performance.now();
    const r=native?nativeRepair(entry,dir,rows.public.length*(direct?2:1)):py(mode,dir,fn,rows.public);
    const applied=performance.now();
    let status='no_candidate';
    if(r.edits.length){
      if(archive){
        const dest=path.join(here,'repariert',task.id);
        fs.mkdirSync(dest,{recursive:true});
        for(const name of Object.keys(task.tide)) fs.copyFileSync(path.join(dir,name+ext),path.join(dest,name+ext));
      }
      if(native){
        fs.appendFileSync(entry,examples('main',rows.hidden,'held'));
        if(!direct) fs.appendFileSync(route,examples(fn,rows.public,'direct'));
        fs.appendFileSync(route,examples(fn,rows.hidden,'held_direct'));
        const p=cmd(bin,['test',entry],undefined,[0,1]);
        if(!p.status){
          assert.equal(JSON.parse(p.stdout).passed,2*(rows.public.length+rows.hidden.length));
          status='accepted';
        } else {
          const failure=JSON.parse(p.stderr);
          assert.equal(failure.code,'E_EXAMPLE');
          status=/^(direct_|held_direct_)/.test(failure.example)?'failed_route':'failed_main';
        }
      } else status=py('accept',dir,fn,[...rows.public,...rows.hidden]).status;
    }
    const end=performance.now();
    const witness=rows.public.find(row=>JSON.stringify(row.inputs)===JSON.stringify(r.inputs));
    assert(witness && witness.expect!==r.actual);
    const messages=[
      {role:'input',body:{auftrag:task.contract,sources:task[language],public:rows.public,
        public_targets:direct?['main','route.'+fn]:['main'],acceptance_targets:['main','route.'+fn]}},
      {role:'input',body:{inputs:r.inputs,expect:witness.expect,actual:r.actual,tested:r.tested,truncated:r.truncated,candidates:r.candidates}},
      {role:'output',body:r.edits.length?{edits:r.edits}:{action:'abstain'}},
      {role:'input',body:{status,cases_per_target:rows.public.length+rows.hidden.length}}
    ];
    const previousGreen=oldLogs[task.id][language+'_after'][1].body;
    assert.deepEqual(r.tested,previousGreen.tested);
    if(!direct) assert.deepEqual(r.candidates,previousGreen.candidates);
    else assert(r.candidates.every(c=>previousGreen.candidates.some(old=>JSON.stringify(c)===JSON.stringify(old))));
    return {messages,ms:end-start,through_apply_ms:applied-start,accept_ms:r.edits.length?end-applied:0,status};
  } finally {fs.rmSync(dir,{recursive:true,force:true});}
}
const mode=process.argv[2];
assert.deepEqual(tasks.map(t=>t.id),plan.tasks);
for(const t of tasks){
  const fn=plan.route_targets[t.id];
  const fields=t.tide.panel.match(/^main (.+) > i$/m)[1];
  const args=fields.split(' ').map(f=>f.split(':')[0]);
  assert.equal(t.tide.panel.trim().split('\n').at(-1),[fn,...args].join(' '));
  assert(t.tide.route.split('\n').includes(fn+' '+fields+' > i'));
  assert(t.python.panel.includes('from route import '+fn+'\n'));
  assert(t.python.panel.trim().endsWith('return '+fn+'('+args.join(', ')+')'));
}
if(mode==='freeze'){
  assert(!fs.existsSync(path.join(here,'fixierung.json')),'already frozen');
  save('fixierung.json',{files:hashes,builds,seed:prior.seed,frozen_utc:new Date().toISOString()});
} else {
  const frozen=read('fixierung.json');
  assert.deepEqual(frozen.files,hashes);
  assert.deepEqual(frozen.builds,builds);
  if(mode==='archive'){
    for(const id of ['cut','tape','telemetry']){
      const task=tasks.find(t=>t.id===id);
      const result=trial(task,'tide_after',true);
      assert.equal(result.status,'accepted');
      assert.deepEqual(result.messages,read('protokolle.json')[id].tide_after);
    }
  } else {
    assert.equal(mode,'run');
    const net=fs.readFileSync('/proc/net/dev','utf8').trim().split('\n').slice(2).map(l=>l.trim().split(':')[0]);
    assert.deepEqual(net,['lo']);
    const core=fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(\d+)$/m)?.[1];
    assert(core,'pin to one CPU');
    const blocks=[],logs={};
    for(let round=-1;round<plan.rounds;round++){
      for(let k=0;k<tasks.length;k++){
        const i=(k+Math.max(round,0))%tasks.length,task=tasks[i];
        const order=orders[(round+i+4)%4].map(a=>arms[a]);
        const block={round,task:task.id,order};
        for(const arm of order){
          const {messages,...metrics}=trial(task,arm);
          logs[task.id]??={};
          if(round===-1) logs[task.id][arm]=messages;
          else assert.deepEqual(logs[task.id][arm],messages);
          block[arm]=metrics;
        }
        if(round>=0) blocks.push(block);
      }
    }
    save('protokolle.json',logs);
    save('messung.json',{environment:{cpu:os.cpus()[Number(core)].model,core,kernel:os.release(),node:process.version,
      tide:cmd(bin,['--version']).stdout.trim(),python:cmd(python,['--version']).stdout.trim(),builds,network:net},
      seed:prior.seed,inputs_sha256:prior.inputs_sha256,audits:prior.audits,model_runs:0,model_input_tokens:0,model_output_tokens:0,blocks});
  }
}
