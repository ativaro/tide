import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import {createInterface} from 'node:readline';

export async function openServices(work, db) {
  const children = [], endpoints = new Map();
  async function close() {
    await Promise.all(children.map(async p => {
      if (p.exitCode !== null || p.signalCode !== null)
        return;
      const done = once(p, 'exit');
      p.kill();
      await done;
    }));
  }
  try {
    for (const arm of ['pre', 'post', 'python']) {
      const cmd = arm === 'python' ?
          ['python3', '-B', path.join(work, 'warm_reference.py'), db] :
          [path.join(work, arm, 'service'), '--listen', '127.0.0.1:0', '--workers', '1', '--db', 'db=' + db];
      const child = spawn(cmd[0], cmd.slice(1), {stdio: ['ignore', 'ignore', 'pipe']});
      children.push(child);
      const lines = createInterface({input: child.stderr});
      const deadline = setTimeout(() => child.kill(), 10000);
      try {
        for await (const line of lines) {
          const m = line.match(/^LISTEN 127\.0\.0\.1:(\d+)$/);
          if (m) {
            endpoints.set(arm, {port: Number(m[1]), pid: child.pid});
            break;
          }
          throw new Error(line);
        }
        assert.ok(endpoints.has(arm), 'Missing service address for ' + arm);
      } finally {
        clearTimeout(deadline);
      }
    }
  } catch (e) {
    await close();
    throw e;
  }
  return {
    close,
    async measure(arm, data) {
      const {port, pid} = endpoints.get(arm);
      const start = process.hrtime.bigint();
      const reply = await new Promise((resolve, reject) => {
        const req = http.request(
            {
              hostname: '127.0.0.1',
              port,
              path: '/import',
              method: 'POST',
              agent: false,
              headers: {
                'Content-Length': Buffer.byteLength(data),
                'Content-Type': 'application/json',
                'Connection': 'close'
              }
            },
            res => {
              let stdout = '';
              res.setEncoding('utf8');
              res.on('data', part => {
                stdout += part;
              });
              res.on('error', reject);
              res.on(
                  'end',
                  () =>
                      resolve({stdout, http_status: res.statusCode, status: res.statusCode === 200 ? 0 : 1}));
            });
        req.on('error', reject);
        req.setTimeout(10000, () => req.destroy(new Error('request timed out')));
        req.end(data);
      });
      const ms = Number(process.hrtime.bigint() - start) / 1e6;
      const peak = fs.readFileSync('/proc/' + pid + '/status', 'utf8').match(/^VmHWM:\s*(\d+) kB$/m);
      return {...reply, stderr: '', ms, peak_kib: Number(peak[1])};
    }
  };
}
