// Post-hoc check of the selected solutions at the existing intermediate entry point.
import assert from 'node:assert/strict';
import {execFileSync,spawnSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const read=name=>JSON.parse(fs.readFileSync(path.join(here,name),'utf8'));
const tasks=read('aufgaben.json'), cases=read('prueffaelle.json'), logs=read('protokolle.json');
const cli=process.env.TIDE_BIN, py=process.env.CPYTHON||'/usr/bin/python3';
assert(cli && path.isAbsolute(cli));
const external=path.join(here,'cpython_suche.py');
const run=(bin,args,input)=>JSON.parse(execFileSync(bin,args,{input:input && JSON.stringify(input),encoding:'utf8'}));
const outputs={};
for(const task of tasks){
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'modul70-'));
  try {
    const rows=cases[task.id], all=[...rows.public,...rows.hidden];
    const fn=task.tide.panel.trim().split('\n').at(-1).split(' ')[0];
    for(const [lang,ext] of [['tide','.tide'],['python','.py']]){
      for(const [name,source] of Object.entries(task[lang])) fs.writeFileSync(path.join(dir,name+ext),source);
    }
    const panel=path.join(dir,'panel.tide');
    fs.appendFileSync(panel,rows.public.map((r,i)=>'\nexample public_'+i+' main\n'+JSON.stringify(r)+'\n').join(''));
    const scan=spawnSync(cli,['test',panel,'--diff','--explain=candidates','--pairs'],{encoding:'utf8'});
    assert.equal(scan.status,1,scan.stderr);
    const repair=JSON.parse(scan.stderr).repair;
    const edits=logs[task.id].tide_after[2].body.edits||[];
    if(edits.length){
      const offers=edits.length===1?repair.candidates.map(edit=>[edit]):repair.pair_candidates;
      assert(offers.some(es=>JSON.stringify(es)===JSON.stringify(edits)));
      const args=['edit',panel,'--base',repair.revision,'--edits',JSON.stringify(edits)];
      if(edits.length===1) assert(run(cli,[...args,'--write']).written);
      else for(const file of run(cli,args).files) fs.writeFileSync(path.join(dir,file.file),file.source);
    }
    const repaired=run(py,['-I','-B','-S',external,'after',dir],rows.public);
    assert.deepEqual(repaired.edits,logs[task.id].python_after[2].body.edits||[]);
    const fields=task.tide.panel.match(/^main (.+) > i$/m)[1];
    const args=fields.split(' ').map(field=>'(get '+field.split(':')[0]+' item)').join(' ');
    const driver=path.join(dir,'audit.tide');
    fs.writeFileSync(driver,'use route\n\nrecord AuditInput\n'+fields+'\n\naudit audit_inputs:*{AuditInput} > *i\nmap i audit_inputs item ('+fn+' '+args+')\n');
    const values=[];
    for(let i=0;i<all.length;i+=12){
      values.push(...run(cli,['run',driver,'--call','audit','--inputs',JSON.stringify({audit_inputs:all.slice(i,i+12).map(r=>r.inputs)})]));
    }
    const script='import importlib,json,sys;sys.path.insert(0,sys.argv[1]);f=getattr(importlib.import_module("route"),sys.argv[2]);print(json.dumps([f(**r["inputs"]) for r in json.load(sys.stdin)]))';
    const other=run(py,['-I','-B','-S','-c',script,dir,fn],all);
    assert.deepEqual(values,other,task.id+' cross-language direct results');
    const mismatch=all.findIndex((r,i)=>values[i]!==r.expect);
    const matches=(rows,offset)=>rows.filter((r,i)=>r.expect===values[offset+i]).length;
    outputs[task.id]={function:fn,public_passed:matches(rows.public,0),hidden_passed:matches(rows.hidden,rows.public.length),
      first_failure:mismatch<0?null:{...all[mismatch],actual:values[mismatch]},
      accepted_at_both:logs[task.id].tide_after[3].body.status==='accepted' && mismatch<0};
  } finally {fs.rmSync(dir,{recursive:true,force:true});}
}
fs.writeFileSync(path.join(here,'modulabnahme.json'),JSON.stringify({same_outputs_in_both_languages:true,tasks:outputs},null,2)+'\n');
