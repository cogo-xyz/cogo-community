import { createCogoClient, ChatEndpoints } from '../src/index.js';
import { randomUUID } from 'node:crypto';

async function wait(ms: number) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const api = new ChatEndpoints(client);

  const projectId = randomUUID();
  const fileName = `sample_${Date.now()}.json`;
  // 1) presign
  const pres = await api.attachmentsPresign({ projectId, fileName });
  // 2) PUT upload
  await fetch(pres.signedUrl, { method: 'PUT', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ hello: 'world' }) });
  // 3) ingest (use returned trace if available)
  const ing = await api.attachmentsIngest({ projectId, storage_key: pres.key });
  const traceId = ing.trace_id;
  // 4) poll result (faster cadence, more attempts)
  let status = 'pending';
  for (let i = 0; i < 30; i++) {
    await wait(1000);
    const res = await api.attachmentsResult(traceId);
    console.log('[ingest]', JSON.stringify(res));
    status = res.status || 'pending';
    if (status === 'ready') break;
  }
  if (status !== 'ready') { console.error('ingest not ready'); process.exit(1); }
}

main().catch((e) => { console.error(e); process.exit(1); });
