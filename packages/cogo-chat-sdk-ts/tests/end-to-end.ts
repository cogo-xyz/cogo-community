import { createCogoClient, ChatEndpoints, buildEditorContext, streamTyped, aggregateCli, selectToast } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const api = new ChatEndpoints(client);

  const editor_context = buildEditorContext({
    openFiles: ['app/pages/login.json'],
    activeFile: 'app/pages/login.json',
    selection: { path: 'app/pages/login.json', range: [5, 15] }
  });

  // 1) Stream design-generate with typed SSE and CLI aggregation
  const url = `${client.baseUrl()}/design-generate`;
  const agg = aggregateCli();
  console.log('[stream] design-generate...');
  const ctrl = new AbortController();
  try {
    await streamTyped(url, { 'content-type': 'application/json', ...client.headers() }, { text: 'Create login UI', editor_context, dev_cli_simulate: true }, {
      signal: ctrl.signal,
      handlers: {
        meta: (m) => console.log('meta', m.trace_id),
        'cli.plan': (v) => agg.onPlan(v),
        'cli.apply': (v) => agg.onApply(v),
        done: () => { console.log('[cli summary]', agg.snapshot()); try { ctrl.abort(); } catch {} },
        error: () => { try { ctrl.abort(); } catch {} }
      }
    });
  } catch (e: any) {
    const name = (e && (e.name || e.constructor?.name)) || '';
    const msg = String(e?.message || e || '');
    if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
  }

  // 2) Run variables.derive to demonstrate ide_hints and mapping
  console.log('[call] variables.derive...');
  const derive = await api.compatVariablesDerive({
    projectId: 'demo',
    page_id: 1,
    page_name: 'loginPage',
    cogo_ui_json: [{ type: 'container' }, { type: 'text', id: 't1' }]
  });
  const hints = (derive as any).ide_hints;
  const toast = selectToast(hints, (process.env.PREF_LANG || 'en'));
  console.log(JSON.stringify({ trace_id: derive.trace_id, mapping: derive.artifacts?.mapping || null, toast, open_file: hints?.open_file, highlight: hints?.highlight }, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
