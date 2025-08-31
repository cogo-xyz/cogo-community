import { createCogoClient } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.warn('SKIP: missing env'); process.exit(0); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });

  // 1) Start a quick design-generate to get trace_id
  const url = `${client.baseUrl()}/design-generate`;
  const ctrl = new AbortController();
  let trace = '';
  const p = fetch(url, { method: 'POST', headers: { 'accept': 'text/event-stream', 'content-type': 'application/json', ...client.headers() }, body: JSON.stringify({ text: 'trace-status quick', dev_queue_sim: true, dev_handoff_after_ms: 50 }) });
  const r = await p;
  if (!r.ok || !r.body) throw new Error('sse failed');
  const reader = r.body.getReader();
  const dec = new TextDecoder();
  let buf = '';
  for (let i = 0; i < 50; i++) {
    const { value, done } = await reader.read();
    if (done) break;
    buf += dec.decode(value, { stream: true });
    let idx;
    while ((idx = buf.indexOf('\n\n')) >= 0) {
      const raw = buf.slice(0, idx).trimEnd();
      buf = buf.slice(idx + 2);
      let ev = 'message'; let data = '';
      for (const line of raw.split('\n')) { if (line.startsWith('event: ')) ev = line.slice(7).trim(); if (line.startsWith('data: ')) data += line.slice(6); }
      try { const j = JSON.parse(data || '{}'); if (!trace && typeof j?.trace_id === 'string') trace = j.trace_id; if (ev === 'handoff' || ev === 'done' || ev === 'error') { try { ctrl.abort(); } catch {} } } catch {}
    }
    if (trace) break;
  }

  // 2) Poll /trace-status
  const statusUrl = `${client.baseUrl()}/trace-status?trace_id=${encodeURIComponent(trace)}`;
  const res = await fetch(statusUrl, { headers: { ...client.headers(), accept: 'application/json' } });
  if (!res.ok) throw new Error(`/trace-status failed: ${res.status}`);
  const js = await res.json();
  if (!js.ok || js.trace_id !== trace) throw new Error('invalid trace-status response');
  console.log('[trace-status]', { status: js.status, trace: js.trace_id });
}

main().catch((e) => { console.error('[Test] trace-status failed:', e); process.exit(1); });


