import { createCogoClient, ChatEndpoints } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const api = new ChatEndpoints(client);

  const info = await api.intentCapabilities();
  console.log('[intent info]', JSON.stringify({ ok: info.ok, requires_source: info.requires_source }, null, 2));

  const resolved = await api.intentResolve('please ui.generate for login page');
  console.log('[intent resolve]', JSON.stringify(resolved, null, 2));

  const symbols = await api.compatSymbolsMap({ projectId: 'demo', page_id: 1, cogo_ui_json: [{ type: 'container' }, { type: 'text', id: 't1' }] });
  console.log('[symbols.map]', JSON.stringify({ trace_id: symbols.trace_id, artifacts: symbols.artifacts }, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
