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
const compare = path.join(experiments, '61_dateiuebergreifende_paare/cpython_pairs.py');
const ast = path.join(experiments, '55_knotenreparatur/cpython_ast.py');
const oracle = path.join(here,'abnahme.tide');
const arms = ['tide','python'];
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
    '../61_dateiuebergreifende_paare/cpython_pairs.py','../60_reparaturzeit/cpython_comparison.py',
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
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'tide69-'));
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
    fs.appendFileSync(entry,'\nrecord AuditInput\n'+fields+'\n\naudit samples:*{AuditInput} > *i\nmap i samples item (main '+args+')\n');
    const result=[];
    for(let i=0;i<inputs.length;i+=12) {
      result.push(...JSON.parse(cmd(tide,['run',entry,'--call','audit','--inputs',json({samples:inputs.slice(i,i+12)})]).stdout));
    }
    return result;
  });
  assert.deepEqual(actual,compareOriginal,'original programs disagree: '+task.id);
  const incorrect=(rows,offset)=>rows.reduce((n,row,i)=>n+Number(actual[i+offset]!==row.expect),0);
  const publicRed=incorrect(cases.public,0);
  assert(publicRed>0,task.id+' lacks a public failure');
  return {public_red:publicRed,hidden_red:incorrect(cases.hidden,cases.public.length),outputs_sha256:digest(json(actual))};
}
function scan(arm,dir,entry,pub) {
  if(arm==='python'){
    const r=py('scan',dir,{public:pub,pool:[]});
    return {inputs:r.inputs,actual:r.actual,singles:r.candidates.map(e=>[e]),pairs:r.pair_candidates,
      tested:[r.tested,r.pair_tested],truncated:[r.truncated,r.pair_truncated]};
  }
  const p=cmd(tide,['test',entry,'--diff','--explain=candidates','--pairs'],undefined,[1]);
  const err=JSON.parse(p.stderr);
  assert.equal(err.code,'E_EXAMPLE',p.stderr);
  const r=err.repair;
  assert(r.execution.complete);
  return {inputs:r.inputs,actual:err.actual,revision:r.revision,singles:r.candidates.map(e=>[e]),pairs:r.pair_candidates,
    tested:[r.candidate_checks.tested,r.pair_checks?.tested??0],truncated:[r.candidate_checks.truncated,r.pair_checks?.truncated??false]};
}
function compact(edit) {
  if(edit.kind) return {node:edit.node,[edit.kind==='op'?'op':'replace']:edit.text};
  return edit;
}
function keyOf(edit) {
  const {node,op,replace}=compact(edit);
  let bits=node.split(':');
  const file=/^\d+$/.test(bits[0])?'panel':bits.shift().split('.')[0];
  const normalized=({'//':'div','%':'mod','==':'eq'})[op] || op || replace;
  return [file,bits[0].padStart(5,'0'),bits[1].padStart(5,'0'),normalized].join(':');
}
function rank(candidate) {return candidate.map(keyOf).sort().join('|');}
function apply(arm,dir,entry,pub,revision,chosen) {
  if(chosen.length===1){
    if(arm==='tide') {
      const r=JSON.parse(cmd(tide,['edit',entry,'--base',revision,'--edits',json(chosen),'--write']).stdout);
      assert.equal(r.written,true);
    } else assert.deepEqual(py('apply',dir,{public:pub,edit:chosen[0]}),{passed:pub.length,success:true});
    return;
  }
  const r=arm==='tide'
    ?JSON.parse(cmd(tide,['edit',entry,'--base',revision,'--edits',json(chosen)]).stdout)
    :py('preview',dir,{public:pub,edits:chosen});
  assert.equal(r.written,false);
  assert.equal(r.examples.passed,pub.length);
  assert.equal(new Set(r.files.map(f=>f.file)).size,2);
  for(const file of r.files) {
    assert.equal(path.basename(file.file),file.file);
    fs.writeFileSync(path.join(dir,file.file),file.source);
  }
}
function accept(arm,dir,entry,pub,hidden) {
  if(arm==='python') return py('accept',dir,{public:pub,hidden}).success;
  fs.appendFileSync(entry,nativeExamples(hidden,'sealed_'));
  const p=cmd(tide,['test',entry],undefined,[0,1]);
  if(p.status===1) {assert.equal(JSON.parse(p.stderr).code,'E_EXAMPLE');return false;}
  return JSON.parse(p.stdout).passed===pub.length+hidden.length;
}
function timed(task,arm,cases) {
  return inScratch(dir=>{
    const entry=project(task,arm,cases.public,dir);
    const start=performance.now();
    const r=scan(arm,dir,entry,cases.public);
    const candidates=(r.singles.length?r.singles:r.pairs).sort((a,b)=>rank(a)<rank(b)?-1:rank(a)>rank(b)?1:0);
    const chosen=candidates[0];
    const scanned=performance.now();
    let applied=scanned,status='no_candidate';
    if(chosen) {
      apply(arm,dir,entry,cases.public,r.revision,chosen);
      applied=performance.now();
      status=accept(arm,dir,entry,cases.public,cases.hidden)?'accepted':'failed_acceptance';
    }
    const end=performance.now();
    const witness=cases.public.find(c=>json(c.inputs)===json(r.inputs));
    assert(witness && witness.expect!==r.actual,task.id+' witness');
    const diag={inputs:r.inputs,expect:witness.expect,actual:r.actual,tested:r.tested,truncated:r.truncated,
      candidates:candidates.map(c=>c.map(compact))};
    const messages=[
      {role:'input',body:{auftrag:task.contract,sources:task[arm],public:cases.public}},
      {role:'input',body:diag},
      {role:'output',body:chosen?{edits:chosen.map(compact)}:{action:'abstain'}},
      {role:'input',body:{status,public:cases.public.length,hidden_checked:status==='accepted'?cases.hidden.length:status==='no_candidate'?0:null}}
    ];
    return {ms:end-start,scan_ms:scanned-start,apply_ms:applied-scanned,accept_ms:end-applied,status,messages};
  });
}
const mode=process.argv[2];
if(mode==='freeze'){
  assert(!fs.existsSync(path.join(here,seedFile)),'already frozen');
  const files=sourceHashes();
  save(seedFile,{files,seed:randomBytes(32).toString('hex'),frozen_utc:new Date().toISOString()});
} else if(mode==='run'){
  const snapshot=read(seedFile);
  assert.deepEqual(sourceHashes(),snapshot.files,'frozen inputs have changed');
  assert.deepEqual(tasks.map(t=>t.id),plan.tasks);
  const net=fs.readFileSync('/proc/net/dev','utf8').trim().split('\n').slice(2).map(line=>line.trim().split(':')[0]);
  assert.deepEqual(net,['lo'],'use a private network namespace');
  const core=fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(\S+)$/m)[1];
  assert(/^\d+$/.test(core),'pin measurement to a single CPU');
  const data={},audits={},transcripts={},pairs=[];
  for(const task of tasks){
    const cases=prepare(task,snapshot.seed);
    data[task.id]=cases;fixtures.set(task.id,cases);
    audits[task.id]=checkOriginal(task,cases);
  }
  save('prueffaelle.json',data);
  for(let round=-1;round<plan.rounds;round++){
    for(let i=0;i<tasks.length;i++){
      const idx=(i+Math.max(0,round))%tasks.length;
      const task=tasks[idx];
      const order=(round+idx)%2===0?arms:[...arms].reverse();
      const pair={round,task:task.id,first:order[0]};
      for(const arm of order){
        const {messages,...result}=timed(task,arm,fixtures.get(task.id));
        transcripts[task.id]??={};
        if(round===-1) transcripts[task.id][arm]=messages;
        else assert.deepEqual(messages,transcripts[task.id][arm]);
        pair[arm]=result;
      }
      if(round>=0) pairs.push(pair);
    }
  }
  save('protokolle.json',transcripts);
  const env={cpu:os.cpus()[Number(core)].model,core,kernel:os.release(),node:process.version,
    tide:cmd(tide,['--version']).stdout.trim(),python:cmd(python,['--version']).stdout.trim(),network:net};
  save('messung.json',{environment:env,seed:snapshot.seed,inputs_sha256:digest(json(data)),additional_model_runs:0,
    model_input_tokens:0,model_output_tokens:0,audits,pairs});
} else throw Error('Expected freeze or run');
