import { createCogoClient, ChatEndpoints } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const api = new ChatEndpoints(client);

  const bdd = await api.bddGenerate({ projectId: 'demo', page_id: 1, cogo_ui_json: [{ type: 'container' }] });
  console.log('[bdd.generate]', JSON.stringify({ trace_id: bdd.trace_id, response: bdd.response }, null, 2));

  const data = await api.dataActionGenerate({ projectId: 'demo', action: { actionType: 'callback', actionId: 'restApi', params: { path: '/login', method: 'POST' } } });
  console.log('[data_action.generate]', JSON.stringify({ trace_id: data.trace_id, artifacts: data.artifacts }, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
