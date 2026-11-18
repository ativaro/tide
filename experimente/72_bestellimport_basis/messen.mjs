// External experiment driver. The TIDE arm uses the installed CLI and native examples.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {performance} from 'node:perf_hooks';

const here=path.dirname(fileURLToPath(import.meta.url));
const output=process.env.RESULT_DIR||here;
const read=f=>JSON.parse(fs.readFileSync(path.join(here,f),'utf8'));
const tasks=read('aufgaben.json'),plan=read('messplan.json'),templates=read('vorlagen.json');
const cli=process.env.TIDE_BIN,py='/usr/bin/python3',check=path.join(here,'cpython_pruefen.py');
const ast=path.resolve(here,'../71_modulvorpruefung/cpython_modul.py');
const langs=['tide','python'],json=JSON.stringify;
function cmd(bin,args,input,allowed=[0]){
  const p=spawnSync(bin,args,{encoding:'utf8',input:input===undefined?undefined:json(input),timeout:18000,maxBuffer:4*1024*1024});
  if(p.error) throw p.error;
  assert(allowed.includes(p.status),[bin,...args,p.status,p.stdout,p.stderr].join(' '));
  return p;
}
const save=(name,v)=>fs.writeFileSync(path.join(output,name),JSON.stringify(v,null,2)+'\n');
const sha=data=>createHash('sha256').update(data).digest('hex');
function sources(task,lang,correct){
  const result={},ext=lang==='tide'?'.tide':'.py';
  for(const phase of (correct?['start','referenzen']:['start'])){
    const folder=path.join(here,phase,task.id);
    if(fs.existsSync(folder)) for(const f of fs.readdirSync(folder).filter(f=>f.endsWith(ext)).sort()){
      result[f]=fs.readFileSync(path.join(folder,f),'utf8');
    }
  }
  return result;
}
function scratch(fn){
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'orders-'));
  try{return fn(dir);}finally{fs.rmSync(dir,{recursive:true,force:true});}
}
function write(dir,files){for(const [name,body] of Object.entries(files)) fs.writeFileSync(path.join(dir,name),body);}
function examples(target,rows,tag){return rows.map((r,i)=>'\nexample '+tag+'_'+i+' '+target+'\n'+json(r)+'\n').join('');}
function addCases(dir,rows,tag,both){
  fs.appendFileSync(path.join(dir,'panel.tide'),examples('main',rows,tag));
  if(both)fs.appendFileSync(path.join(dir,'route.tide'),examples('relay',rows,tag+'_module'));
}
function tideTests(dir,count){
  const p=cmd(cli,['test',path.join(dir,'panel.tide')],undefined,[0,1]);
  if(p.status){const err=JSON.parse(p.stderr);assert.equal(err.code,'E_EXAMPLE',p.stderr);return false;}
  assert.equal(JSON.parse(p.stdout).passed,count);
  return true;
}
function pyTests(dir,rows,both){
  return JSON.parse(cmd(py,['-I','-B','-S',check,dir,both?'both':'main'],rows).stdout);
}
function nativeSearch(dir,publicCount){
  const entry=path.join(dir,'panel.tide');
  const err=JSON.parse(cmd(cli,['test',entry,'--diff','--explain=candidates','--pairs'],undefined,[1]).stderr);
  assert.equal(err.code,'E_EXAMPLE');
  const r=err.repair;
  assert(r.execution.complete);
  const key=edits=>edits.map(e=>{
    const p=e.node.split(':');const name=/^\d+$/.test(p[0])?'panel':p.shift().split('.')[0];
    return [name,p[0].padStart(5,'0'),p[1].padStart(5,'0'),e.op||e.replace].join(':');
  }).sort().join('|');
  const options=(r.candidates.length?r.candidates.map(e=>[e]):r.pair_candidates).toSorted((a,b)=>key(a)<key(b)?-1:key(a)>key(b)?1:0);
  const edits=options[0]||[];
  if(edits.length){
    const args=['edit',entry,'--base',r.revision,'--edits',json(edits)];
    const patch=JSON.parse(cmd(cli,edits.length===1?[...args,'--write']:args).stdout);
    assert.equal(patch.examples.passed,2*publicCount);
    if(edits.length===1) assert(patch.written);
    else{assert.equal(new Set(patch.files.map(f=>f.file)).size,2);
      for(const f of patch.files){assert.equal(f.file,path.basename(f.file));fs.writeFileSync(path.join(dir,f.file),f.source);}
    }
  }
  return {witness:{inputs:r.inputs,actual:err.actual},tested:[r.candidate_checks.tested,r.pair_checks.tested],
    truncated:[r.candidate_checks.truncated,r.pair_checks.truncated],options,edits};
}
function fromBlank(task,lang,dir){
  const args=task.signatur.split(' ').map(f=>f.split(':')),kinds=args.map(a=>a[1]).join(' ');
  const opts=templates[kinds]||[],native=lang==='tide';let tested=0,edits=[];
  for(const option of opts){
    tested++;
    const expr=option[native?0:1].replace(/\$([ab])/g,(_,key)=>args[key==='a'?0:1][0]);
    const body=native?'main '+task.signatur+' > i\n'+expr+'\n':
      'def main('+args.map(([n,k])=>n+': '+(k==='i'?'int':'str')).join(', ')+') -> int:\n    return '+expr+'\n';
    write(dir,{[native?'panel.tide':'panel.py']:body});
    if(native)addCases(dir,task.public,'public',false);
    if(native?tideTests(dir,task.public.length):pyTests(dir,task.public,false)){
      edits=[{source:body}];break;
    }
  }
  return {tested:[tested,0],truncated:[false,false],options:edits.length?[edits]:[],edits};
}
function solve(task,lang){
  const native=lang==='tide',fromZero=task.id[0]==='W',startFiles=sources(task,lang,false);
  return scratch(dir=>{
    write(dir,startFiles);if(native&&!fromZero)addCases(dir,task.public,'public',true);
    const start=performance.now();
    let r;
    if(fromZero)r=fromBlank(task,lang,dir);
    else if(native)r=nativeSearch(dir,task.public.length);
    else{
      const p=JSON.parse(cmd(py,['-I','-B','-S',ast,'after',dir,'relay'],task.public).stdout);
      r={witness:{inputs:p.inputs,actual:p.actual},tested:p.tested,truncated:p.truncated,options:p.candidates,edits:p.edits};
    }
    let status='no_candidate';
    if(r.edits.length){
      const rows=[...task.public,...task.abnahme];
      if(native)addCases(dir,task.abnahme,'accept',!fromZero);
      status=(native?tideTests(dir,rows.length*(fromZero?1:2)):pyTests(dir,rows,!fromZero))?'accepted':'failed_acceptance';
    }
    const ms=performance.now()-start;
    const messages=[
      {role:'input',body:{auftrag:task.auftrag,signature:task.signatur,sources:startFiles,public:task.public,targets:fromZero?['main']:['main','relay']}},
      {role:'input',body:{witness:r.witness||null,tested:r.tested,truncated:r.truncated,options:r.options}},
      {role:'output',body:r.edits.length?{edits:r.edits}:{action:'abstain'}},
      {role:'input',body:{status}}
    ];
    return {messages,ms,status};
  });
}
function program(task,lang,dir,inputs){
  if(lang==='python')return [py,'-I','-B','-S',check,dir,'run',json(inputs)];
  const {db,...other}=inputs,cmdline=[cli,'run',path.join(dir,'panel.tide')];
  if(db)cmdline.push('--db','db='+db);
  return [...cmdline,'--inputs',json(other)];
}
function verify(task,lang){
  return scratch(dir=>{
    write(dir,sources(task,lang,true));const rows=[...task.public,...task.abnahme],both=task.id[0]!=='W';
    if(lang==='tide')addCases(dir,rows,'oracle',both);
    assert(lang==='tide'?tideTests(dir,rows.length*(both?2:1)):pyTests(dir,rows,both),task.id);
    if(task.id==='W05'){
      const db=path.join(dir,'probe.db');
      for(const [ids,expected] of [[["a","a","'q"],2],[["'q","猫"],3]]){
        const [bin,...args]=program(task,lang,dir,{db,ids});
        assert.equal(JSON.parse(cmd(bin,args).stdout),expected);
      }
      const stored=cmd('/usr/bin/sqlite3',['-json',db,'SELECT id FROM receipt ORDER BY id']).stdout;
      assert.deepEqual(JSON.parse(stored).map(r=>r.id),["'q","a","猫"]);
    }
    return rows.length;
  });
}
function runtime(task,lang){
  return scratch(dir=>{
    write(dir,sources(task,lang,true));const row=task.abnahme[0];
    const args=program(task,lang,dir,row.inputs);
    const p=cmd('/usr/bin/zsh',['-fc','TIMEFMT="TIDE_RSS=%M REAL=%*E"; time "$@"','--',...args]);
    assert.equal(JSON.parse(p.stdout),row.expect);
    const match=p.stderr.match(/^TIDE_RSS=(\d+) REAL=(\d+(?:\.\d+)?)$/m);
    assert(match,p.stderr);return {ms:Number(match[2])*1000,rss_kib:Number(match[1])};
  });
}
const net=fs.readFileSync('/proc/net/dev','utf8').trim().split('\n').slice(2).map(l=>l.trim().split(':')[0]);
assert.deepEqual(net,['lo']);
const core=fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(\d+)$/m)?.[1];
assert(core);assert(!fs.existsSync('/home/ativaro/.config/tide'));assert(!fs.existsSync('/home/ativaro/.local/share/tide'));
const audit={};
for(const t of tasks)for(const l of langs){(audit[t.id]??={})[l]=verify(t,l);}
const logs={},runs=[],repairs=[];
for(let round=-1;round<plan.rounds;round++){
 for(let j=0;j<tasks.length;j++){
   const i=(j+Math.max(0,round))%tasks.length,t=tasks[i];
   const order=(i+round+1)%2?langs:[...langs].reverse();
   const row={id:t.id,round,order},repair={id:t.id,round,order};
   for(const l of order){
     row[l]=runtime(t,l);
     if(round<plan.search_rounds){
       const {messages,...metrics}=solve(t,l);repair[l]=metrics;
       if(round===-1)(logs[t.id]??={})[l]=messages;
       else assert.deepEqual(logs[t.id][l],messages);
     }
   }
   if(round>=0){runs.push(row);if(round<plan.search_rounds)repairs.push(repair);}
 }
}
const resolveBackend=path.dirname(fs.realpathSync(cli));
save('protokolle.json',logs);
save('messung.json',{environment:{cpu:os.cpus()[Number(core)].model,core,network:net,kernel:os.release(),node:process.version,
 tide:cmd(cli,['--version']).stdout.trim(),python:cmd(py,['--version']).stdout.trim(),inspector_sha256:sha(fs.readFileSync(path.join(resolveBackend,'inspector')))},
 model_runs:0,model_tokens:0,audit,runs,repairs});
