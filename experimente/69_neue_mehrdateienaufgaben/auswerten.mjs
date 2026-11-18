// Offline accounting, after the timed runs. Only the tokenizer vocabulary is loaded.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const directory=path.dirname(fileURLToPath(import.meta.url));
const read=name=>JSON.parse(fs.readFileSync(path.join(directory,name),'utf8'));
const raw=read('messung.json'), logs=read('protokolle.json'), plan=read('versuchsplan.json');
const cases=read('prueffaelle.json'), snapshot=read('fixierung.json');
const hash=data=>createHash('sha256').update(data).digest('hex');
assert.equal(snapshot.seed,raw.seed);
assert.equal(hash(JSON.stringify(cases)),raw.inputs_sha256);
assert.equal(raw.pairs.length,plan.tasks.length*plan.rounds);
for(const [name,expected] of Object.entries(snapshot.files)) assert.equal(hash(fs.readFileSync(path.join(directory,name))),expected);
const vocab=process.env.TOKENIZER_JSON;
const vocabHash=hash(fs.readFileSync(vocab));
assert(plan.tokens.includes(vocabHash),'Unexpected tokenizer vocabulary');
const arms=['tide','python'];
const bodies=plan.tasks.flatMap(task=>arms.flatMap(arm=>logs[task][arm].map(m=>JSON.stringify(m.body))));
const code=[
  'from tokenizers import Tokenizer, __version__','import json, sys',
  'tok=Tokenizer.from_file(sys.argv[1])',
  'parts=tok.encode_batch(json.load(sys.stdin),add_special_tokens=False)',
  'print(json.dumps({"version":__version__,"counts":[len(p.ids) for p in parts]}))'
].join('\n');
const tokenizer=spawnSync(process.env.TOKENIZER_PYTHON||'python3',['-I','-B','-c',code,vocab],
  {input:JSON.stringify(bodies),encoding:'utf8'});
assert.equal(tokenizer.status,0,tokenizer.stderr);
const {counts,version}=JSON.parse(tokenizer.stdout);
assert.equal(counts.length,bodies.length);
function median(values) {
  const v=values.toSorted((a,b)=>a-b), k=Math.floor(v.length/2);
  return v.length%2?v[k]:(v[k-1]+v[k])/2;
}
function nearest(values,p) {
  return values.toSorted((a,b)=>a-b)[Math.ceil(values.length*p)-1];
}
function times(pairs){
  const out={};
  for(const arm of arms){
    const values=pairs.map(p=>p[arm].ms);
    out[arm]={median:median(values),p95:nearest(values,.95),
      median_by_phase:Object.fromEntries(['scan_ms','apply_ms','accept_ms'].map(k=>[k,median(pairs.map(p=>p[arm][k]))]))};
  }
  const ratios=pairs.map(p=>p.python.ms/p.tide.ms),differences=pairs.map(p=>p.python.ms-p.tide.ms);
  return {...out,paired_ratio:median(ratios),ratio_q1:nearest(ratios,.25),ratio_q3:nearest(ratios,.75),
    median_difference_ms:median(differences),tide_faster_pairs:differences.filter(d=>d>0).length,pairs:pairs.length};
}
function signature(candidates){
  return candidates.map(edits=>edits.map(e=>e.node.split('.')[0]+':'+(e.op||e.replace))
    .sort().join('|')).sort();
}
const jobs={},allTokens={tide:0,python:0},acceptedTokens={tide:0,python:0};
let index=0;
for(const task of plan.tasks){
  const trial=raw.pairs.filter(p=>p.task===task);
  assert.equal(trial.length,plan.rounds);
  assert.equal(trial.filter(p=>p.first==='tide').length,plan.rounds/2);
  const diag=logs[task];
  const l=diag.tide[1].body,r=diag.python[1].body;
  for(const key of ['inputs','expect','actual','tested','truncated']) assert.deepEqual(l[key],r[key],task+' '+key);
  assert.deepEqual(l.truncated,[false,false]);
  assert.deepEqual(signature(l.candidates),signature(r.candidates),task+' green candidates');
  for(const p of trial){
    assert.equal(p.python.status,p.tide.status);
    for(const arm of arms) assert.equal(p[arm].status,diag[arm][3].body.status);
  }
  const tokens={};
  for(const arm of arms){
    const [source,diagnostic,decision,final]=counts.slice(index,index+4);index+=4;
    const input=source+diagnostic+final,output=decision,total=input+output;
    tokens[arm]={source,diagnostic,decision,final,input,output,total};
    allTokens[arm]+=total;
    if(trial[0][arm].status==='accepted') acceptedTokens[arm]+=total;
  }
  jobs[task]={status:trial[0].tide.status,candidate_checks:l.tested,green:l.candidates.length,tokens,time:times(trial)};
}
const successful=raw.pairs.filter(p=>p.tide.status==='accepted'),count=Object.values(jobs).filter(j=>j.status==='accepted').length;
const summary={tasks:plan.tasks.length,accepted_tasks:count,time_ms:{success:times(successful),abstention:times(raw.pairs.filter(p=>p.tide.status!=='accepted'))},
  protocol_tokens:{tokenizer:'Llama BPE, 128000 vocabulary entries',tokenizers_version:version,vocabulary_sha256:vocabHash,
    accepted_tasks_total:acceptedTokens,all_tasks_total:allTokens,all_attempts_per_success:Object.fromEntries(arms.map(a=>[a,allTokens[a]/count]))},
  per_task:jobs};
fs.writeFileSync(path.join(directory,'auswertung.json'),JSON.stringify(summary,null,2)+'\n');
