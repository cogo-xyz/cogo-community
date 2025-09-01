// Minimal client for Figma Plugin (no npm deps)
// - Use fetch for HTTP calls to Supabase Edge Function bridge
// - For realtime, prefer polling or an external SSE relay provided by server if available

export type EnqueueOptions = {
  edgeUrl: string;              // https://<project>.functions.supabase.co/figma-plugin
  anonKey: string;              // SUPABASE_ANON_KEY
  projectId: string;            // UUID
  cogoProjectId?: string;       // optional internal cogo project id
  sessionId?: string;           // optional session scope
  shard?: number;               // optional
  idempotencyKey?: string;      // optional idempotency key
};

export async function enqueue(opts: EnqueueOptions, tool: string, params: Record<string, unknown>): Promise<{ ok: boolean; id?: string; error?: string; trace_id?: string }>{
  const url = `${opts.edgeUrl.replace(/\/$/, '')}/enqueue`;
  const body = { toolset: 'figma', tool, params, sessionId: opts.sessionId, projectId: opts.projectId, cogoProjectId: opts.cogoProjectId, shard: opts.shard || 0, idempotencyKey: opts.idempotencyKey };
  const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', 'authorization': `Bearer ${opts.anonKey}`, 'apikey': opts.anonKey }, body: JSON.stringify(body) });
  const j = await res.json().catch(() => ({} as any));
  if (!res.ok || j?.ok !== true) return { ok: false, error: String(j?.error || `HTTP ${res.status}`) };
  return { ok: true, id: String(j.id || ''), trace_id: String(j.trace_id || '') };
}

export async function pollResult(edgeUrl: string, anonKey: string, messageId: string, timeoutMs = 60000): Promise<{ ok: boolean; status?: string; result?: unknown; error?: string }>{
  const url = `${edgeUrl.replace(/\/$/, '')}/result?id=${encodeURIComponent(messageId)}`;
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    const res = await fetch(url, { headers: { 'authorization': `Bearer ${anonKey}`, 'apikey': anonKey } });
    const j = await res.json().catch(() => ({} as any));
    if (!res.ok || j?.ok !== true) return { ok: false, error: String(j?.error || `HTTP ${res.status}`) };
    if (j?.status === 'ok') return { ok: true, status: 'ok', result: j?.event?.payload?.result ?? null };
    if (j?.status === 'error') return { ok: false, status: 'error', error: j?.event?.payload?.reason || 'error' };
    await new Promise((r) => setTimeout(r, 1000));
  }
  return { ok: false, status: 'timeout', error: 'timeout' };
}

export async function respond(edgeUrl: string, anonKey: string, args: { projectId: string; cogoProjectId?: string; sessionId?: string; messageId: string; promptType: string; payload: Record<string, unknown> }): Promise<{ ok: boolean; error?: string }>{
  const url = `${edgeUrl.replace(/\/$/, '')}/respond`;
  const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', 'authorization': `Bearer ${anonKey}`, 'apikey': anonKey }, body: JSON.stringify({ project_id: args.projectId, session_id: args.sessionId, message_id: args.messageId, prompt_type: args.promptType, payload: args.payload, cogoProjectId: args.cogoProjectId }) });
  if (!res.ok) return { ok: false, error: `HTTP ${res.status}` };
  const j = await res.json().catch(() => ({} as any));
  return j?.ok === true ? { ok: true } : { ok: false, error: String(j?.error || 'unknown') };
}

// Direct compat calls (no queue): useful inside Figma plugin
export async function uuiDirect(edgeUrl: string, anonKey: string | undefined, path: string, body: Record<string, unknown>) {
  const url = `${edgeUrl.replace(/\/$/, '')}/figma-compat/uui/${path.replace(/^\//,'')}`;
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (anonKey) { headers['authorization'] = `Bearer ${anonKey}`; headers['apikey'] = anonKey; }
  const res = await fetch(url, { method: 'POST', headers, body: JSON.stringify(body) });
  const j = await res.json().catch(() => ({} as any));
  return { ok: res.ok && j?.ok === true, status: res.status, body: j };
}

// Usage hint:
// - projectId (UUID) is required and identifies the platform project scope.
// - cogoProjectId (UUID) is optional and used for internal cogo-agent/platform scoping; it is independent from projectId.
// Example:
// const opts = {
//   edgeUrl: 'https://<project>.functions.supabase.co/figma-plugin',
//   anonKey: '<SUPABASE_ANON_KEY>',
//   projectId: '<project_uuid>',
//   cogoProjectId: '<cogo_project_uuid>', // optional
//   sessionId: 'sess_1234',
// };
// const enq = await enqueue(opts, 'convert_to_creatego', { project_id: 1, page_id: 1, figma_json: [] });
// if (enq.ok) { const res = await pollResult(opts.edgeUrl, opts.anonKey, enq.id!); }
// // Or direct (inside plugin):
// const direct = await uuiDirect('https://<project>.functions.supabase.co', '<SUPABASE_ANON_KEY>', 'symbols/map', { projectId: opts.projectId, page_id: 34, creatego_json: [] });


