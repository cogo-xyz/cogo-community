import { createCogoClient, ChatEndpoints, newIdempotencyKey } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const api = new ChatEndpoints(client);

  const idem = newIdempotencyKey('sdk-test');
  const ctrl = new AbortController();
  const onEvent = (e: string) => {
    if (e === 'done' || e === 'error') {
      console.log('[done]');
      try { ctrl.abort(); } catch {}
    }
  };

  // First call
  try {
    await api.streamDesignGenerate({ text: 'Create login UI' }, (e) => onEvent(e), { idempotency_key: idem, signal: ctrl.signal as any });
  } catch (e: any) {
    const name = (e && (e.name || e.constructor?.name)) || '';
    const msg = String(e?.message || e || '');
    if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
  }
  // Second call with same key (should be reused/no-op server-side)
  const ctrl2 = new AbortController();
  try {
    await api.streamDesignGenerate({ text: 'Create login UI' }, (e) => {
      if (e === 'done' || e === 'error') { try { ctrl2.abort(); } catch {} }
    }, { idempotency_key: idem, signal: ctrl2.signal as any });
  } catch (e: any) {
    const name = (e && (e.name || e.constructor?.name)) || '';
    const msg = String(e?.message || e || '');
    if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
