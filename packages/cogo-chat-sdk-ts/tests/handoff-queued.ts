import { createCogoClient, streamOrRealtime, createSupabaseClient, createSupabaseTraceSubscriber } from '../src/index.js';

async function main() {
  const EDGE = process.env.SUPABASE_EDGE || (process.env.SUPABASE_PROJECT_ID ? `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1` : '');
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE || !ANON) { console.log('SKIP: missing env'); return; }
  const client = createCogoClient({ edgeBase: EDGE, anonKey: ANON });
  const url = `${client.baseUrl()}/design-generate`;
  const headers = { 'content-type': 'application/json', accept: 'text/event-stream', ...client.headers() };

  let queuedSeen = false, handoffSeen = false, doneSeen = false;
  let subFactory: any = null;
  if (process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY) {
    const sb = await createSupabaseClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
    subFactory = createSupabaseTraceSubscriber(sb);
  }

  console.log('[handoff] start');
  await streamOrRealtime(url, headers, { text: 'demo', dev_queue_sim: true, dev_handoff_after_ms: 100, dev_cli_simulate: true }, {
    subscribeTrace: subFactory || undefined,
    handlers: {
      queued: (q: any) => { queuedSeen = true; console.log('[handoff] queued', q?.trace_id); },
      handoff: (h: any) => { handoffSeen = true; console.log('[handoff] handoff', h?.trace_id); },
      done: (d: any) => { doneSeen = true; console.log('[handoff] done', d?.trace_id); },
      error: (e: any) => { throw new Error(e?.message || 'error'); }
    },
    idleMs: 5000
  });

  if (!queuedSeen) console.warn('WARN: queued not seen (dev flags may be off)');
  if (!handoffSeen) console.warn('WARN: handoff not seen (dev flags may be off)');
  console.log('[handoff] summary', { queuedSeen, handoffSeen, doneSeen });
  if (!doneSeen) throw new Error('done not seen');
}

main().catch((e) => { console.error(e); process.exit(1); });


