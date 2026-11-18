// Measurement driver. TIDE owns the case generation, labels, guest execution and tests.
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash, randomBytes} from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {performance} from 'node:perf_hooks';

const here = path.dirname(fileURLToPath(import.meta.url));
const experiments = path.dirname(here);
const plan = read('versuchsplan.json');
const tasks = read('aufgaben.json');
const tide = process.env.TIDE_BIN;
assert(tide && path.isAbsolute(tide), 'Set TIDE_BIN to the installed CLI');
const python = process.env.CPYTHON || '/usr/bin/python3';
const compare = path.join(here,'cpython_suche.py');
const before = process.env.TIDE_BEFORE;
assert(before && path.isAbsolute(before),'Set TIDE_BEFORE');
const ast = path.join(experiments, '55_knotenreparatur/cpython_ast.py');
const oracle = path.join(here,'abnahme.tide');
const arms = ['tide_before','python_before','tide_after','python_after'];
const fixtures = new Map();
const seedFile = 'fixierung.json';
const digest = value => createHash('sha256').update(value).digest('hex');
const json = JSON.stringify;

function read(file) { return JSON.parse(fs.readFileSync(path.join(here,file),'utf8')); }
function save(file,value) { fs.writeFileSync(path.join(here,file),JSON.stringify(value,null,2)+'\n'); }
function cmd(exe,args,input,allowed=[0]) {
  const p = spawnSync(exe,args,{input,encoding:'utf8',timeout:15000,maxBuffer:8*1024*1024});
  if (p.error) throw p.error;
  assert(allowed.includes(p.status),[exe,args[0],p.status,p.stdout,p.stderr].join(' '));
  return p;
}
function py(mode,dir,data) {
  return JSON.parse(cmd(python,['-I','-B','-S',compare,mode,dir],json(data)).stdout);
}
function sourceHashes() {
  const files = ['abnahme.tide','aufgaben.json','versuchsplan.json','messen.mjs',
    'cpython_suche.py','suche.patch','../../native/bootstrap/explain.tide','../60_reparaturzeit/cpython_comparison.py',
    '../55_knotenreparatur/cpython_ast.py','../../tide.lock','../../tide'];
  return Object.fromEntries(files.map(f=>[f,digest(fs.readFileSync(path.join(here,f)))]));
}
function makeCases(task,ids) {
  return JSON.parse(cmd(tide,['run',oracle,'--call',task.id,'--inputs',json({ids})]).stdout);
}
function prepare(task,seed) {
  const pub = makeCases(task,plan.public_ids);
  const seen = new Set(pub.map(row=>json(row.inputs)));
  assert.equal(seen.size,plan.public_ids.length,task.id+' duplicate public input');
  const order = Array.from({length:65536},(_,id)=>[digest(seed+':'+task.id+':'+id),id]);
  order.sort((a,b)=>a[0]<b[0]?-1:1);
  const hidden = [];
  for(let i=0;hidden.length<plan.hidden_per_task;i+=16) {
    assert(i<order.length);
    for(const row of makeCases(task,order.slice(i,i+16).map(pair=>pair[1]))) {
      const key=json(row.inputs);
      if(!seen.has(key)) {seen.add(key);hidden.push(row);}
      if(hidden.length===plan.hidden_per_task) break;
    }
  }
  return {public:pub,hidden};
}
function example(row,i,prefix) {return '\nexample '+prefix+i+' main\n'+json(row)+'\n';}
function nativeExamples(rows,tag) {return rows.map((r,i)=>example(r,i,tag)).join('');}
function project(task,arm,rows,dir) {
  const ext = arm==='tide'?'.tide':'.py';
  for(const [name,body] of Object.entries(task[arm])) {
    fs.writeFileSync(path.join(dir,name+ext),body+(name==='panel' && arm==='tide'?nativeExamples(rows,'public_'):''));
  }
  return path.join(dir,'panel'+ext);
}
function inScratch(fn) {
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'tide70-'));
  try {return fn(dir);} finally {fs.rmSync(dir,{recursive:true,force:true});}
}
function checkOriginal(task,cases) {
  const inputs=[...cases.public,...cases.hidden].map(x=>x.inputs);
  const compareOriginal=inScratch(dir=>{
    project(task,'python',[],dir);
    return JSON.parse(cmd(python,['-I','-B','-S',ast,'run',dir],json(inputs)).stdout);
  });
  const actual=inScratch(dir=>{
    const entry=project(task,'tide',[],dir);
    const fields=task.tide.panel.match(/^main (.+) > i$/m)[1];
    const args=fields.split(' ').map(field=>'(get '+field.split(':')[0]+' item)').join(' ');
    fs.appendFileSync(entry,'\nrecord AuditInput\n'+fields+'\n\naudit audit_inputs:*{AuditInput} > *i\nmap i audit_inputs item (main '+args+')\n');
    const result=[];
    for(let i=0;i<inputs.length;i+=12) {
      result.push(...JSON.parse(cmd(tide,['run',entry,'--call','audit','--inputs',json({audit_inputs:inputs.slice(i,i+12)})]).stdout));
    }
    return result;
  });
  assert.deepEqual(actual,compareOriginal,'original programs disagree: '+task.id);
  const incorrect=(rows,offset)=>rows.reduce((n,row,i)=>n+Number(actual[i+offset]!==row.expect),0);
  const publicRed=incorrect(cases.public,0);
  assert(publicRed>0,task.id+' lacks a public failure');
  return {public_red:publicRed,hidden_red:incorrect(cases.hidden,cases.public.length),outputs_sha256:digest(json(actual))};
}
function editOrder(edits) {
  return edits.map(edit=>{
    const pieces=edit.node.split(':');
    const name=/^\d+$/.test(pieces[0])?'panel':pieces.shift().split('.')[0];
    return [name,pieces[0].padStart(5,'0'),pieces[1].padStart(5,'0'),edit.op||edit.replace].join(':');
  }).sort().join('|');
}
function nativeRepair(bin,dir,entry,publicCount) {
  const failure=JSON.parse(cmd(bin,['test',entry,'--diff','--explain=candidates','--pairs'],undefined,[1]).stderr);
  assert.equal(failure.code,'E_EXAMPLE');
  const r=failure.repair;
  assert(r.execution.complete);
  const options=r.candidates.length?r.candidates.map(c=>[c]):r.pair_candidates;
  const candidates=options.toSorted((a,b)=>editOrder(a)<editOrder(b)?-1:editOrder(a)>editOrder(b)?1:0);
  const edits=candidates[0]||[];
  if(edits.length){
    const args=['edit',entry,'--base',r.revision,'--edits',json(edits)];
    const p=JSON.parse(cmd(bin,edits.length===1?[...args,'--write']:args).stdout);
    assert.equal(p.examples.passed,publicCount);
    if(edits.length===2) {
      assert.equal(new Set(p.files.map(f=>f.file)).size,2);
      for(const f of p.files) {
        assert.equal(path.basename(f.file),f.file);
        fs.writeFileSync(path.join(dir,f.file),f.source);
      }
    } else assert(p.written);
  }
  return {inputs:r.inputs,actual:failure.actual,candidates,edits,
    tested:[r.candidate_checks.tested,r.pair_checks.tested],truncated:[r.candidate_checks.truncated,r.pair_checks.truncated]};
}
function trial(task,arm,cases) {
  const [language,generation]=arm.split('_'), native=language==='tide';
  const bin=generation==='before'?before:tide;
  return inScratch(dir=>{
    const entry=project(task,language,cases.public,dir);
    const start=performance.now();
    const result=native?nativeRepair(bin,dir,entry,cases.public.length):py(generation,dir,cases.public);
    const applied=performance.now();
    let status='no_candidate';
    if(result.edits.length) {
      let accepted;
      if(native) {
        fs.appendFileSync(entry,nativeExamples(cases.hidden,'held_'));
        const p=cmd(bin,['test',entry],undefined,[0,1]);
        if(p.status) assert.equal(JSON.parse(p.stderr).code,'E_EXAMPLE');
        accepted=p.status===0 && JSON.parse(p.stdout).passed===cases.public.length+cases.hidden.length;
      } else accepted=py('accept',dir,[...cases.public,...cases.hidden]);
      status=accepted?'accepted':'failed_acceptance';
    }
    const end=performance.now();
    const witness=cases.public.find(c=>json(c.inputs)===json(result.inputs));
    assert(witness && witness.expect!==result.actual);
    const messages=[
      {role:'input',body:{auftrag:task.contract,sources:task[language],public:cases.public}},
      {role:'input',body:{inputs:result.inputs,expect:witness.expect,actual:result.actual,tested:result.tested,truncated:result.truncated,candidates:result.candidates}},
      {role:'output',body:result.edits.length?{edits:result.edits}:{action:'abstain'}},
      {role:'input',body:{status,public:cases.public.length,hidden_passed:status==='accepted'?cases.hidden.length:null}}
    ];
    return {status,messages,ms:end-start,through_apply_ms:applied-start,accept_ms:result.edits.length?end-applied:0};
  });
}
function inspectorHash(bin) {
  return digest(fs.readFileSync(path.join(path.dirname(fs.realpathSync(bin)),'inspector')));
}
const mode=process.argv[2];
if(mode==='freeze'){
  assert(!fs.existsSync(path.join(here,seedFile)),'already frozen');
  const files=sourceHashes();
  assert.deepEqual(tasks.map(t=>t.id),plan.tasks);
  const builds={before:inspectorHash(before),after:inspectorHash(tide)};
  assert.notEqual(builds.before,builds.after);
  save(seedFile,{files,builds,seed:randomBytes(32).toString('hex'),frozen_utc:new Date().toISOString()});
} else if(mode==='run'){
  const frozen=read(seedFile);
  assert.deepEqual(frozen.files,sourceHashes());
  const net=fs.readFileSync('/proc/net/dev','utf8').trim().split('\n').slice(2).map(l=>l.trim().split(':')[0]);
  assert.deepEqual(net,['lo']);
  const core=fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(\S+)$/m)[1];
  assert(/^\d+$/.test(core));
  const data={},audits={},logs={},blocks=[];
  for(const task of tasks) {
    const rows=prepare(task,frozen.seed);
    data[task.id]=rows;
    audits[task.id]=checkOriginal(task,rows);
  }
  save('prueffaelle.json',data);
  // Each arm occupies each position three times and precedes every other arm equally.
  const orders=[[0,1,3,2],[1,2,0,3],[2,3,1,0],[3,0,2,1]];
  for(let round=-1;round<plan.rounds;round++) {
    for(let i=0;i<tasks.length;i++) {
      const idx=(i+Math.max(round,0))%tasks.length, task=tasks[idx];
      const order=orders[(round+idx+4)%4].map(k=>arms[k]);
      const block={round,task:task.id,order};
      for(const arm of order) {
        const {messages,...metrics}=trial(task,arm,data[task.id]);
        logs[task.id]??={};
        if(round===-1) logs[task.id][arm]=messages;
        else assert.deepEqual(messages,logs[task.id][arm]);
        block[arm]=metrics;
      }
      if(round>=0) blocks.push(block);
    }
  }
  save('protokolle.json',logs);
  save('messung.json',{environment:{cpu:os.cpus()[Number(core)].model,core,kernel:os.release(),node:process.version,
    tide:cmd(tide,['--version']).stdout.trim(),python:cmd(python,['--version']).stdout.trim(),
    builds:{before:inspectorHash(before),after:inspectorHash(tide)},network:net},seed:frozen.seed,
    inputs_sha256:digest(json(data)),model_runs:0,model_input_tokens:0,model_output_tokens:0,audits,blocks});
} else throw Error('Expected freeze or run');
