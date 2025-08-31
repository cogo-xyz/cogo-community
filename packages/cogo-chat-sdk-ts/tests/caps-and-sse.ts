import { createCogoClient, ChatEndpoints } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const api = new ChatEndpoints(client);

  // Capabilities
  const caps = await client.getCapabilities();
  console.log('[caps]', JSON.stringify({ ok: caps.ok, editor_context_support: caps.editor_context_support, events: caps.sse_events }, null, 2));

  // SSE design-generate (dev_cli_simulate)
  console.log('[sse] design-generate');
  const ctrl = new AbortController();
  try {
    await api.streamDesignGenerate({ text: 'Create login UI', dev_cli_simulate: true }, (event, data) => {
      if (event === 'ready' || event === 'meta' || event === 'cli.plan' || event === 'cli.apply' || event === 'cli.done' || event === 'done' || event === 'aborted' || event === 'error') {
        console.log(`event: ${event}\n${data}\n`);
      }
      if (event === 'done' || event === 'error') {
        try { ctrl.abort(); } catch {}
      }
    }, { signal: ctrl.signal });
  } catch (e: any) {
    const name = (e && (e.name || e.constructor?.name)) || '';
    const msg = String(e?.message || e || '');
    if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
