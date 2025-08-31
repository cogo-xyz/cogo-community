import { createCogoClient, ChatEndpoints } from '../src/index.js';

async function main() {
  const EDGE_BASE = process.env.SUPABASE_EDGE || `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`;
  const ANON = process.env.SUPABASE_ANON_KEY || '';
  if (!EDGE_BASE || !ANON) { console.error('Missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY'); process.exit(2); }

  const client = createCogoClient({ edgeBase: EDGE_BASE, anonKey: ANON });
  const api = new ChatEndpoints(client);

  const payload = {
    projectId: 'demo',
    page_id: 1,
    page_name: 'loginPage',
    cogo_ui_json: [{ type: 'container', id: 'root', children: [{ type: 'text', id: 't1' }] }]
  };
  const res = await api.compatVariablesDerive(payload);
  console.log(JSON.stringify({ trace_id: res.trace_id, artifacts: res.artifacts, ide_hints: (res as any).ide_hints || null }, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
