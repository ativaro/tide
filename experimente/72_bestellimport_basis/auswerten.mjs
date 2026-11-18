// Local postprocessing; the tokenizer is not a model.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const read=f=>JSON.parse(fs.readFileSync(path.join(here,f),'utf8'));
const cfg=read('messplan.json'),tasks=read('aufgaben.json'),raw=read('messung.json'),logs=read('protokolle.json');
const seal=read('versiegelung.json'),languages=['tide','python'];
const sha=data=>createHash('sha256').update(data).digest('hex');
for(const file of ['vertrag.sha256','werkzeuge.sha256'])for(const line of fs.readFileSync(path.join(here,file),'utf8').trim().split('\n')){
  assert.equal(sha(fs.readFileSync(path.join(here,line.slice(66)))),line.slice(0,64),line.slice(66));
}
assert.equal(new Set(seal.tasks.map(t=>t.commitment)).size,15);
assert.equal(new Set(tasks.map(t=>t.id)).size,15);
for(const f of cfg.familien){
  assert.equal(tasks.filter(t=>t.id[0]===f).length,5);
  assert.equal(seal.tasks.filter(t=>t.family===f).length,5);
}
const vocab=process.env.TOKENIZER_JSON;
const hash=sha(fs.readFileSync(vocab));assert(cfg.tokens.includes(hash));
const messages=tasks.flatMap(t=>languages.flatMap(l=>logs[t.id][l]));
const code=['from tokenizers import Tokenizer,__version__','import json,sys',
  'rows=Tokenizer.from_file(sys.argv[1]).encode_batch(json.load(sys.stdin),add_special_tokens=False)',
  'print(json.dumps([__version__, [len(r.ids) for r in rows]]))'].join('\n');
const p=spawnSync(process.env.TOKENIZER_PYTHON,['-I','-B','-c',code,vocab],{encoding:'utf8',input:JSON.stringify(messages.map(m=>JSON.stringify(m.body)))});
assert.equal(p.status,0,p.stderr);
const [version,counts]=JSON.parse(p.stdout);assert.equal(counts.length,messages.length);
const median=a=>{const v=a.toSorted((a,b)=>a-b),n=v.length;return n%2?v[n>>1]:(v[n/2]+v[n/2-1])/2;};
const distribution=a=>({median:median(a),p95:a.toSorted((a,b)=>a-b)[Math.ceil(.95*a.length)-1]});
const rowmap={};let next=0;
for(const task of tasks){
  assert.equal(task.public.length,3);assert.equal(task.abnahme.length,4);
  assert.equal(new Set([...task.public,...task.abnahme].map(r=>JSON.stringify(r.inputs))).size,7);
  const id=task.id;rowmap[id]={};
  for(const [list,n] of [[raw.runs,cfg.rounds],[raw.repairs,cfg.search_rounds]]){
    const rows=list.filter(r=>r.id===id);assert.equal(rows.length,n);assert.equal(new Set(rows.map(r=>r.round)).size,n);
    assert.equal(rows.filter(r=>r.order[0]==='tide').length,n/2);
  }
  for(const l of languages){
    const input=counts[next]+counts[next+1]+counts[next+3],output=counts[next+2];next+=4;
    const diag=logs[id][l][1].body,status=logs[id][l][3].body.status;
    assert.equal(raw.audit[id][l],7);
    assert(raw.repairs.filter(r=>r.id===id).every(r=>r[l].status===status));
    rowmap[id][l]={status,input_tokens:input,output_tokens:output,total_tokens:input+output,tested:diag.tested,truncated:diag.truncated,
      solve_ms:median(raw.repairs.filter(r=>r.id===id).map(r=>r[l].ms)),
      program_ms:median(raw.runs.filter(r=>r.id===id).map(r=>r[l].ms)),peak_kib:median(raw.runs.filter(r=>r.id===id).map(r=>r[l].rss_kib))};
  }
}
assert.equal(next,counts.length);
function summary(ids){
  const group={},runs=raw.runs.filter(r=>ids.includes(r.id)),search=raw.repairs.filter(r=>ids.includes(r.id));
  for(const l of languages){
    const items=ids.map(id=>rowmap[id][l]),ok=items.filter(r=>r.status==='accepted');
    const total=items.reduce((n,r)=>n+r.total_tokens,0);
    group[l]={solved:ok.length,attempts:items.length,program_ms:distribution(runs.map(r=>r[l].ms)),
      peak_kib:distribution(runs.map(r=>r[l].rss_kib)),success_ms:distribution(search.filter(r=>r[l].status==='accepted').map(r=>r[l].ms)),
      all_search_ms:distribution(search.map(r=>r[l].ms)),input_tokens:items.reduce((n,r)=>n+r.input_tokens,0),
      output_tokens:items.reduce((n,r)=>n+r.output_tokens,0),total_tokens:total,
      tokens_all_per_success:total/ok.length,tokens_accepted:ok.reduce((n,r)=>n+r.total_tokens,0)};
  }
  const paired=search.filter(r=>languages.every(l=>r[l].status==='accepted'));
  group.paired_success_ratio=median(paired.map(r=>r.python.ms/r.tide.ms));
  group.paired_program_ratio=median(runs.map(r=>r.python.ms/r.tide.ms));
  return group;
}
const groups=Object.fromEntries(['W','E','R'].map(f=>[f,summary(tasks.filter(t=>t.id[0]===f).map(t=>t.id))]));
const result={all:summary(tasks.map(t=>t.id)),groups,by_task:rowmap,
  tokenizer:{version,vocabulary_sha256:hash},model_calls:0,actual_model_tokens:0};
fs.writeFileSync(path.join(here,'auswertung.json'),JSON.stringify(result,null,2)+'\n');
