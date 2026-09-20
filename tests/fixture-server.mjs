// Transport fixture only: deliberately contains no Clef checking or proof logic.
import fs from 'node:fs';

const [logPath, ...args] = process.argv.slice(2);
const record = (event) => fs.appendFileSync(logPath, JSON.stringify({ pid: process.pid, ...event }) + '\n');
record({ event: 'start', args });

function send(message) {
  const body = JSON.stringify({ jsonrpc: '2.0', ...message });
  process.stdout.write('Content-Length: ' + Buffer.byteLength(body) + '\r\n\r\n' + body);
}

function receive(message) {
  record({ event: 'receive', ...message });
  const { id, method, params } = message;
  if (method === 'initialize') {
    send({ id, result: { capabilities: {
      positionEncoding: 'utf-16',
      textDocumentSync: { openClose: true, change: 1 },
      hoverProvider: true,
    }, serverInfo: { name: 'Lattice transport fixture' } } });
  } else if (method === 'textDocument/didOpen' || method === 'textDocument/didChange') {
    const text = params.textDocument.text ?? params.contentChanges[0].text;
    send({ method: 'textDocument/publishDiagnostics', params: {
      uri: params.textDocument.uri,
      version: params.textDocument.version,
      diagnostics: text.includes('bad') ? [{
        range: { start: { line: 0, character: 0 }, end: { line: 0, character: 3 } },
        severity: 1, code: 'FIXTURE001', source: 'transport fixture', message: 'fixture error',
      }] : [],
    } });
  } else if (method === 'textDocument/hover') {
    send({ id, result: { contents: { kind: 'plaintext', value: 'fixture hover' } } });
  } else if (method === 'shutdown') {
    send({ id, result: null });
  } else if (method === 'exit') {
    process.exit(0);
  } else if (id !== undefined) {
    send({ id, error: { code: -32601, message: 'Unsupported fixture method: ' + method } });
  }
}

let pending = Buffer.alloc(0);
process.stdin.on('data', (chunk) => {
  pending = Buffer.concat([pending, chunk]);
  while (true) {
    const separator = pending.indexOf('\r\n\r\n');
    if (separator < 0) break;
    const header = pending.subarray(0, separator).toString('ascii');
    const length = Number(/Content-Length:\s*(\d+)/i.exec(header)?.[1]);
    if (!Number.isSafeInteger(length)) throw new Error('Invalid LSP Content-Length');
    if (pending.length < separator + 4 + length) break;
    const body = pending.subarray(separator + 4, separator + 4 + length);
    pending = pending.subarray(separator + 4 + length);
    receive(JSON.parse(body.toString('utf8')));
  }
});

process.on('SIGTERM', () => { record({ event: 'terminated' }); process.exit(1); });
