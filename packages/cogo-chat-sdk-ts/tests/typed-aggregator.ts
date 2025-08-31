import { createCogoClient, streamTyped, aggregateCli } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const url = `${client.baseUrl()}/design-generate`;
  const agg = aggregateCli();
  const ctrl = new AbortController();
  try {
    await streamTyped(url, { 'content-type': 'application/json', ...client.headers() }, { text: 'Create login UI', dev_cli_simulate: true }, {
      signal: ctrl.signal,
      handlers: {
        'cli.plan': (v) => agg.onPlan(v),
        'cli.apply': (v) => agg.onApply(v),
        done: () => { console.log('[summary]', agg.snapshot()); try { ctrl.abort(); } catch {} },
        error: () => { try { ctrl.abort(); } catch {} }
      }
    });
  } catch (e) {
    const name = (e && (e.name || e.constructor?.name)) || '';
    const msg = String((e as any)?.message || e || '');
    if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
