// Sensitivity of the write baseline to repeated CPython interpreter startups.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {performance} from 'node:perf_hooks';
const here=path.dirname(fileURLToPath(import.meta.url)),read=f=>JSON.parse(fs.readFileSync(path.join(here,f)));
const tasks=read('aufgaben.json').filter(t=>t.id[0]==='W'),tpl=read('vorlagen.json'),logs=read('protokolle.json');
const py='/usr/bin/python3',cli=process.env.TIDE_BIN;
const net=fs.readFileSync('/proc/net/dev','utf8').trim().split('\n').slice(2).map(s=>s.trim().split(':')[0]);
assert.deepEqual(net,['lo']);assert.match(fs.readFileSync('/proc/self/status','utf8'),/^Cpus_allowed_list:\s*\d+$/m);
function call(bin,args,data,ok=[0]){
  const p=spawnSync(bin,args,{input:data===undefined?undefined:JSON.stringify(data),encoding:'utf8',timeout:18000});
  assert(ok.includes(p.status),p.stderr);return p;
}
const example=(rows,tag)=>rows.map((r,i)=>'\nexample '+tag+i+' main\n'+JSON.stringify(r)+'\n').join('');
function run(t,lang){
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'draft-')),native=lang==='tide',file=path.join(dir,native?'panel.tide':'panel.py');
  try {
    const start=performance.now(),fields=t.signatur.split(' ').map(f=>f.split(':'));
    const options=tpl[fields.map(f=>f[1]).join(' ')]||[];
    const sources=options.map(pair=>{
      const expr=pair[native?0:1].replace(/\$([ab])/g,(_,k)=>fields[k==='a'?0:1][0]);
      return native?'main '+t.signatur+' > i\n'+expr+'\n':'def main('+fields.map(([n,k])=>n+': '+(k==='i'?'int':'str')).join(', ')+') -> int:\n    return '+expr+'\n';
    });
    let tested=0,source=null;
    if(native){
      for(const draft of sources){
        tested++;
        fs.writeFileSync(file,draft+example(t.public,'public'));
        const p=call(cli,['test',file],undefined,[0,1]);
        if(p.status===0){assert.equal(JSON.parse(p.stdout).passed,3);source=draft;break;}
        assert.equal(JSON.parse(p.stderr).code,'E_EXAMPLE');
      }
      if(source){fs.appendFileSync(file,example(t.abnahme,'held'));assert.equal(JSON.parse(call(cli,['test',file]).stdout).passed,7);}
    }else if(sources.length){
      ({tested,source}=JSON.parse(call(py,['-I','-B','-S',path.join(here,'cpython_entwuerfe.py'),file],{sources,public:t.public}).stdout));
      if(source)assert.equal(JSON.parse(call(py,['-I','-B','-S',path.join(here,'cpython_pruefen.py'),dir,'main'],[...t.public,...t.abnahme]).stdout),true);
    }
    const ms=performance.now()-start,prev=logs[t.id][lang];assert.equal(prev[1].body.tested[0],tested);
    assert.equal(prev[2].body.edits?.[0].source||null,source);return {ms,success:!!source};
  }finally{fs.rmSync(dir,{recursive:true,force:true});}
}
const blocks=[];
for(let round=-1;round<8;round++)for(let k=0;k<tasks.length;k++){
  const i=(k+Math.max(0,round))%tasks.length,t=tasks[i],order=(i+round+1)%2?['tide','python']:['python','tide'];
  const b={id:t.id,round,order};for(const l of order)b[l]=run(t,l);
  if(round>=0)blocks.push(b);
}
const med=a=>{const v=a.sort((x,y)=>x-y);return (v[(v.length-1)>>1]+v[v.length>>1])/2;};
const success=blocks.filter(b=>b.tide.success&&b.python.success);
fs.writeFileSync(path.join(process.env.RESULT_DIR,'kontrollmessung.json'),JSON.stringify({blocks,success_medians_ms:{
 tide:med(success.map(b=>b.tide.ms)),python:med(success.map(b=>b.python.ms)),
 paired_ratio:med(success.map(b=>b.python.ms/b.tide.ms))}},null,2)+'\n');
