// Offline accounting of the four frozen arms and paired wall-clock measurements.
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=process.argv[2]?path.resolve(process.argv[2]):path.dirname(fileURLToPath(import.meta.url));
const read=f=>JSON.parse(fs.readFileSync(path.join(here,f),'utf8'));
const sha=b=>createHash('sha256').update(b).digest('hex');
const raw=read('messung.json'), logs=read('protokolle.json'), plan=read('versuchsplan.json');
const cases=read('prueffaelle.json'), frozen=read('fixierung.json');
assert.equal(raw.seed,frozen.seed);
assert.equal(raw.inputs_sha256,sha(JSON.stringify(cases)));
assert.deepEqual(raw.environment.builds,frozen.builds);
assert.equal(raw.blocks.length,plan.rounds*plan.tasks.length);
for(const [file,expected] of Object.entries(frozen.files)) {
  assert.equal(sha(fs.readFileSync(path.join(here,file))),expected,file);
}

const languages=['tide','python'], generations=['before','after'];
const tokenizer=process.env.TOKENIZER_JSON, vocabHash=sha(fs.readFileSync(tokenizer));
assert(plan.tokens.includes(vocabHash));
const messages=plan.tasks.flatMap(id=>generations.flatMap(g=>languages.flatMap(l=>logs[id][l+'_'+g])));
const code=[
  'from tokenizers import Tokenizer, __version__','import json,sys',
  'encoded=Tokenizer.from_file(sys.argv[1]).encode_batch(json.load(sys.stdin),add_special_tokens=False)',
  'print(json.dumps([__version__,[len(row.ids) for row in encoded]]))'
].join('\n');
const result=spawnSync(process.env.TOKENIZER_PYTHON||'python3',['-I','-B','-c',code,tokenizer],
  {input:JSON.stringify(messages.map(m=>JSON.stringify(m.body))),encoding:'utf8'});
assert.equal(result.status,0,result.stderr);
const [version,counts]=JSON.parse(result.stdout);
assert.equal(counts.length,messages.length);
function median(values) {
  const v=values.toSorted((a,b)=>a-b), k=Math.floor(v.length/2);
  return v.length%2?v[k]:(v[k-1]+v[k])/2;
}
function quantile(values,p) {return values.toSorted((a,b)=>a-b)[Math.ceil(values.length*p)-1];}
function time(blocks,g){
  const summary={blocks:blocks.length};
  for(const lang of languages){
    const values=blocks.map(b=>b[lang+'_'+g].ms);
    summary[lang]={median_ms:median(values),p95_ms:quantile(values,.95)};
  }
  const ratios=blocks.map(b=>b['python_'+g].ms/b['tide_'+g].ms);
  return {...summary,median_paired_ratio:median(ratios),q1_ratio:quantile(ratios,.25),q3_ratio:quantile(ratios,.75),
    tide_faster:ratios.filter(v=>v>1).length};
}
// Compare public options across different source syntaxes, retaining module and call argument order.
function signature(edit){
  const module=/^\d/.test(edit.node)?'panel':edit.node.split('.')[0];
  const expr=edit.replace||'';
  if(edit.op) return [module,edit.op];
  if(/byte_len|\.encode\(/.test(expr)) return [module,'utf8'];
  if(/text_rfind|\.rfind\(/.test(expr)) return [module,'last'];
  return [module,'swap',...expr.match(/\w+/g)];
}
const signatures=sets=>sets.map(edits=>edits.map(signature).sort());
let cursor=0;
const jobs={};
for(const id of plan.tasks){
  jobs[id]={};
  const rows=raw.blocks.filter(b=>b.task===id), data=cases[id];
  assert.equal(rows.length,plan.rounds);
  assert.equal(new Set(rows.map(b=>b.round)).size,plan.rounds);
  assert.equal(data.public.length,plan.public_ids.length);
  assert.equal(data.hidden.length,plan.hidden_per_task);
  assert.equal(new Set([...data.public,...data.hidden].map(c=>JSON.stringify(c.inputs))).size,data.public.length+data.hidden.length);
  assert(raw.audits[id].public_red>0);
  for(const g of generations){
    const native=logs[id]['tide_'+g], other=logs[id]['python_'+g];
    const diag=native[1].body;
    for(const key of ['inputs','expect','actual','tested','truncated']) assert.deepEqual(diag[key],other[1].body[key],id+' '+key);
    assert.deepEqual(diag.truncated,[false,false],id);
    assert.deepEqual(signatures(diag.candidates),signatures(other[1].body.candidates),id);
    assert.deepEqual(signatures([native[2].body.edits||[]]),signatures([other[2].body.edits||[]]),id);
    assert.deepEqual(native[3].body,other[3].body,id);
    const status=native[3].body.status, tokens={};
    for(const lang of languages){
      const arm=lang+'_'+g;
      for(let i=0;i<4;i++) assert.equal(rows.filter(b=>b.order[i]===arm).length,plan.rounds/4);
      assert(rows.every(b=>b[arm].status===status && b[arm].ms>0));
      const [source,diagnosis,decision,receipt]=counts.slice(cursor,cursor+4);
      cursor+=4;
      const input=source+diagnosis+receipt;
      tokens[lang]={source,diagnosis,decision,receipt,input,output:decision,total:input+decision};
    }
    jobs[id][g]={status,green:diag.candidates.length,tested:diag.tested,tokens,time:time(rows,g)};
  }
}
assert.equal(cursor,counts.length);
const summary={};
for(const g of generations){
  const passed=plan.tasks.filter(id=>jobs[id][g].status==='accepted');
  const blocks=raw.blocks;
  const tokens={};
  for(const lang of languages){
    const sums=ids=>Object.fromEntries(['input','output','total'].map(key=>[key,ids.reduce((n,id)=>n+jobs[id][g].tokens[lang][key],0)]));
    tokens[lang]={all:sums(plan.tasks),accepted:sums(passed),all_per_success:sums(plan.tasks).total/passed.length};
  }
  summary[g]={accepted:passed.length,total:plan.tasks.length,tokens,
    successful_time:time(blocks.filter(b=>passed.includes(b.task)),g),
    unsuccessful_time:time(blocks.filter(b=>!passed.includes(b.task)),g),all_time:time(blocks,g)};
}
const output={summary,tokenizer:{version,sha256:vocabHash,description:'Llama BPE, no special tokens'},
  tasks:jobs};
fs.writeFileSync(path.join(here,'auswertung.json'),JSON.stringify(output,null,2)+'\n');
