// Validate that inserting a bus event via /figma-compat/uui/ingest
// causes the RealtimeRelayWorker to broadcast to trace:{traceId}
import { createCogoClient, createSupabaseTraceSubscriber } from '../src/index.js';
import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';

const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
const ANON_KEY = process.env.SUPABASE_ANON_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;

if (!EDGE_BASE || !ANON_KEY) {
  console.warn('SKIP: SUPABASE_PROJECT_ID/SUPABASE_EDGE and SUPABASE_ANON_KEY are required for realtime-relay test.');
  process.exit(0);
}
if (!SUPABASE_URL) {
  console.warn('SKIP: SUPABASE_URL is required to create a Realtime subscriber for realtime-relay test.');
  process.exit(0);
}

async function delay(ms: number) { return new Promise((r) => setTimeout(r, ms)); }

async function main() {
  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON_KEY });
  const sb = createClient(SUPABASE_URL, ANON_KEY, { auth: { persistSession: false } });
  const subscribeTrace = createSupabaseTraceSubscriber(sb);

  // 1) Subscribe first using a known traceId, then call ingest with that traceId
  const projectId = randomUUID();
  const traceId = randomUUID();
  const storageKey = `uploads/${projectId}/relay_test_${Date.now()}.json`;
  let received = false;
  const unsubscribe = await subscribeTrace(traceId, (event, payload) => {
    if (event === 'uui_ingest_requested' && payload?.trace_id === traceId) received = true;
  });

  const res = await fetch(`${client.baseUrl()}/figma-compat/uui/ingest`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'accept': 'application/json', ...client.headers() },
    body: JSON.stringify({ projectId, storage_key: storageKey, traceId }),
  });
  if (!res.ok) throw new Error(`ingest failed: ${res.status}`);

  for (let i = 0; i < 30 && !received; i++) await delay(500);
  await unsubscribe();
  if (!received) throw new Error('Did not receive uui_ingest_requested broadcast for trace channel');
  console.log('[Test] realtime-relay passed.');
}

main().catch((e) => { console.error('[Test] realtime-relay failed:', e); process.exit(1); });


