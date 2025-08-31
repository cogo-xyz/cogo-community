// Figma Plugin main code
figma.showUI(__html__, { width: 520, height: 700 });

import type { } from 'typescript';

type ConvertMsg = { type: 'convert'; payload: { edge: string; anon: string; projectId: string; agentId?: string } };
type IngestMsg = { type: 'ingest'; payload: { edge: string; anon: string; projectId: string; fileName?: string; json?: string; agentId?: string } };
type ChatSseMsg = { type: 'chat_sse'; payload: { edge: string; anon: string; text: string; sessionId?: string; agentId?: string } };
type ContextSseMsg = { type: 'context_sse'; payload: { edge: string; anon: string; jobId: string; cursor: number; agentId?: string } };
type GenerateMsg = { type: 'uui_generate'; payload: { edge: string; anon: string; projectId?: string; prompt?: string; cogo?: string; agentId?: string } };
type GenerateLlmMsg = { type: 'uui_generate_llm'; payload: { edge: string; anon: string; projectId?: string; prompt: string; cogo?: string; agentId?: string } };
// New
type PresenceRegisterMsg = { type: 'presence_register'; payload: { edge: string; anon: string; projectId?: string; fileKey?: string; userId?: string; ttlMs?: number; agentId?: string; language?: string; pageId?: number } };
type PresenceUnregMsg = { type: 'presence_unregister'; payload: { edge: string; anon: string; sessionId?: string; agentId?: string } };
type StartMsg = { type: 'context_start'; payload: { edge: string; anon: string; figmaUrl?: string; agentId?: string } };
type ApplyMsg = { type: 'context_apply'; payload: { edge: string; anon: string; jobId: string; projectId: string; pageId?: number; agentId?: string } };

type AnyMsg = ConvertMsg|IngestMsg|ChatSseMsg|ContextSseMsg|GenerateMsg|GenerateLlmMsg|PresenceRegisterMsg|PresenceUnregMsg|StartMsg|ApplyMsg;

function headers(anon: string | undefined, agentId?: string) {
  const h: any = { 'content-type': 'application/json' };
  if (anon) { h['Authorization'] = 'Bearer ' + anon; h['apikey'] = anon; }
  if (agentId && agentId.trim()) { h['x-agent-id'] = agentId.trim(); }
  return h;
}

function postStatus(message: string) { figma.ui.postMessage({ type: 'status', message }); }

async function retry<T>(fn: () => Promise<T>, opts?: { retries?: number; backoffMs?: number }): Promise<T> {
  const retries = (opts && typeof opts.retries === 'number') ? opts.retries : 3;
  const back = (opts && typeof opts.backoffMs === 'number') ? opts.backoffMs : 500;
  let lastErr: any;
  for (let i = 0; i <= retries; i++) {
    try { return await fn(); } catch (e) { lastErr = e; }
    await new Promise((r) => setTimeout(r, back * Math.max(1, i)));
  }
  throw lastErr;
}

async function readSse(url: string, init: any = {}) {
  const baseHeaders: any = (init.headers || {});
  baseHeaders['accept'] = 'text/event-stream';
  const res: any = await fetch(url, { method: init.method || 'POST', headers: baseHeaders, body: init.body, signal: init.signal });
  if (!res.ok || !res.body) throw new Error('sse_failed_' + res.status);
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = '';
  while (true) {
    const r = await reader.read();
    const value = r.value; const done = r.done;
    if (done) break;
    buf += decoder.decode(value, { stream: true });
    let idx: number;
    while ((idx = buf.indexOf('\n\n')) >= 0) {
      const frame = buf.slice(0, idx); buf = buf.slice(idx + 2);
      const lines = frame.split('\n');
      let evt = ''; let dat = '';
      for (const line of lines) {
        if (line.indexOf('event:') === 0) evt = line.replace(/^event:\s*/, '').trim();
        if (line.indexOf('data:') === 0) dat = line.replace(/^data:\s*/, '');
      }
      try { if (init.onEvent) init.onEvent(evt, dat); } catch {}
    }
  }
}

let presenceSessionId = '';
let heartbeatTimer: any = null;
let persistentPluginId = '';
let prefLanguage: string = 'auto';
let prefPageId: number | undefined = undefined;
function uuid() { try { return crypto.randomUUID(); } catch { return (Date.now()+ '-' + Math.random().toString(16).slice(2)); } }
(function augmentGlobalGuards(){
  // lightweight UUID v4 validation (accepts generic UUID forms)
  (globalThis as any).__isUuid = (s: unknown) => typeof s === 'string' && /^(?:[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$/.test(s);
})();
(async () => {
  try {
    const saved = await figma.clientStorage.getAsync('plugin_id');
    if (typeof saved === 'string' && saved.trim()) { persistentPluginId = saved.trim(); }
    else { persistentPluginId = 'fp-' + uuid(); await figma.clientStorage.setAsync('plugin_id', persistentPluginId); }
    figma.ui.postMessage({ type: 'presence', ok: true, session_id: persistentPluginId });
  } catch {}
})();

async function presenceRegister(edge: string, anon: string, projectId?: string, fileKey?: string, userId?: string, ttlMs?: number, agentId?: string) {
  const body: any = { plugin_id: (presenceSessionId || persistentPluginId) };
  if (projectId) body.project_id = projectId;
  try { if (!fileKey && (figma as any).fileKey) fileKey = String((figma as any).fileKey || ''); } catch {}
  if (fileKey) body.file_key = fileKey;
  if (userId) body.user_id = userId;
  body.ttl_ms = (typeof ttlMs === 'number' && ttlMs > 0) ? ttlMs : 60000;
  const res = await retry(() => fetch(edge.replace(/\/$/, '') + '/figma-plugin/presence/register', { method: 'POST', headers: headers(anon, agentId), body: JSON.stringify(body) }));
  const j = await res.json(); if (!res.ok || !j || !j.ok) throw new Error('presence_register_failed');
  presenceSessionId = String(j.session_id || '');
  const hbMs = Number(j.heartbeat_ms || 15000);
  if (heartbeatTimer) clearInterval(heartbeatTimer);
  heartbeatTimer = setInterval(async () => {
    try { await fetch(edge.replace(/\/$/, '') + '/figma-plugin/presence/heartbeat', { method: 'POST', headers: headers(anon, agentId), body: JSON.stringify({ session_id: presenceSessionId }) }); } catch {}
  }, hbMs);
  figma.ui.postMessage({ type: 'presence', ok: true, session_id: presenceSessionId });
}

async function presenceUnregister(edge: string, anon: string, agentId?: string) {
  if (!presenceSessionId) return;
  try { await fetch(edge.replace(/\/$/, '') + '/figma-plugin/presence/unregister', { method: 'POST', headers: headers(anon, agentId), body: JSON.stringify({ session_id: presenceSessionId }) }); } catch {}
  try { clearInterval(heartbeatTimer); } catch {}
  heartbeatTimer = null; presenceSessionId = '';
}

figma.on('close', () => { presenceSessionId = ''; try { clearInterval(heartbeatTimer); } catch {} });

figma.ui.onmessage = async (msg: AnyMsg) => {
  if ((msg as any).type === 'presence_register') {
    try {
      const p = (msg as PresenceRegisterMsg).payload;
      if (typeof p.language === 'string' && p.language.trim()) prefLanguage = p.language.trim();
      if (typeof p.pageId === 'number') prefPageId = p.pageId;
      await presenceRegister(p.edge, p.anon, p.projectId, p.fileKey, p.userId, p.ttlMs, p.agentId);
    } catch (e) {
      figma.ui.postMessage({ type: 'presence', ok: false, error: String((e as Error).message || e) });
    }
    return;
  }
  if ((msg as any).type === 'presence_unregister') {
    try { const p = (msg as PresenceUnregMsg).payload; await presenceUnregister(p.edge, p.anon, p.agentId); figma.ui.postMessage({ type: 'presence', ok: true, unregistered: true }); } catch {}
    return;
  }

  if ((msg as any).type === 'context_start') {
    try {
      const p = (msg as StartMsg).payload;
      const base = p.edge.replace(/\/$/, '');
      let figmaUrl = (p.figmaUrl || '').trim();
      if (!figmaUrl) {
        // Try to auto-build from current file and selection
        let fk = '';
        try { fk = String((figma as any).fileKey || ''); } catch {}
        const sel = figma.currentPage.selection;
        const nodeId = (sel && sel.length > 0) ? String(sel[0].id || '') : '';
        if (fk && nodeId) figmaUrl = 'https://www.figma.com/file/' + fk + '?node-id=' + encodeURIComponent(nodeId);
      }
      if (!figmaUrl) throw new Error('figma_url_required');
      const res = await retry(() => fetch(base + '/figma-context/start', { method: 'POST', headers: headers(p.anon, p.agentId), body: JSON.stringify({ figma_url: figmaUrl }) }), { retries: 2, backoffMs: 700 });
      const j = await res.json();
      figma.ui.postMessage({ type: 'context_start_result', ok: res.ok, json: j });
    } catch (e) {
      figma.ui.postMessage({ type: 'context_start_result', ok: false, error: String((e as Error).message || e) });
    }
    return;
  }

  if ((msg as any).type === 'context_apply') {
    try {
      const p = (msg as ApplyMsg).payload;
      const base = p.edge.replace(/\/$/, '');
      const body: any = { job_id: p.jobId, projectId: p.projectId };
      if (typeof p.pageId === 'number') body.page_id = p.pageId;
      const res = await retry(() => fetch(base + '/figma-context/apply', { method: 'POST', headers: headers(p.anon, p.agentId), body: JSON.stringify(body) }), { retries: 1, backoffMs: 500 });
      const j = await res.json();
      figma.ui.postMessage({ type: 'context_apply_result', ok: res.ok, json: j });
    } catch (e) {
      figma.ui.postMessage({ type: 'context_apply_result', ok: false, error: String((e as Error).message || e) });
    }
    return;
  }

  // existing handlers
  if (msg.type === 'convert') {
    try {
      // Guard: require selection
      if (!figma.currentPage.selection.length) { throw new Error('No selection. Select at least one node.'); }
      // Guard: projectId must be UUID if provided
      const pjId = (msg as ConvertMsg).payload.projectId;
      if (!(globalThis as any).__isUuid(pjId)) { throw new Error('Invalid projectId. Expected UUID'); }
      postStatus('Converting selection → UUI & Cogo...');
      const selection = figma.currentPage.selection;
      const nodes = selection.map((n) => ({ type: n.type.toLowerCase(), id: n.id, name: (n as any).name || n.type }));
      const body = {
        user_id: 'figma-plugin',
        session_id: 'sess_' + Date.now(),
        projectId: pjId,
        page_id: (typeof prefPageId === 'number' ? prefPageId : 1),
        page_name: figma.currentPage.name,
        cogo_ui_json: nodes,
        intent: { language: prefLanguage, keywords: ['symbols.identify'] }
      };
      const idem = 'sym-' + Date.now();
      const res = await retry(() => fetch((msg as ConvertMsg).payload.edge.replace(/\/$/, '') + '/figma-compat/uui/symbols/map', { method: 'POST', headers: { ...headers((msg as ConvertMsg).payload.anon, (msg as ConvertMsg).payload.agentId), 'Idempotency-Key': idem }, body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
      const json = await res.json();
      if (res.status === 413 || (json && json.error === 'payload_too_large')) {
        figma.ui.postMessage({ type: 'result', ok: false, error: 'Payload too large. Use Upload & Ingest flow.' });
        return;
      }
      figma.ui.postMessage({ type: 'result', ok: res.ok, json });
      try {
        const ih = (json && json.ide_hints) || null;
        if (ih) {
          const t = (prefLanguage || 'en').toLowerCase();
          const toast = ih[`toast_${t}`] || ih.toast || '';
          if (toast) postStatus(String(toast));
        }
      } catch {}
    } catch (e) {
      figma.ui.postMessage({ type: 'result', ok: false, error: String((e as Error)?.message || e) });
    }
    return;
  }

  if (msg.type === 'ingest') {
    const edge = (msg as IngestMsg).payload.edge.replace(/\/$/, '');
    try {
      // Guard: projectId must be UUID
      if (!(globalThis as any).__isUuid((msg as IngestMsg).payload.projectId)) { throw new Error('Invalid projectId. Expected UUID'); }
      // 1) Prepare JSON (from textarea or selection)
      postStatus('Preparing JSON...');
      let payload: any;
      if ((msg as IngestMsg).payload.json && (msg as IngestMsg).payload.json!.trim()) {
        try { payload = JSON.parse((msg as IngestMsg).payload.json!); } catch { throw new Error('Invalid JSON in input'); }
      } else {
        const selection = figma.currentPage.selection;
        if (!selection.length) { throw new Error('No selection and no JSON provided'); }
        const nodes = selection.map((n) => ({ type: n.type.toLowerCase(), id: n.id, name: (n as any).name || n.type }));
        payload = { cogo_ui_json: nodes };
      }

      // 2) presign
      postStatus('Requesting presign...');
      const fileName = ((msg as IngestMsg).payload.fileName && (msg as IngestMsg).payload.fileName!.trim()) || `figma_${Date.now()}.json`;
      const pres = await retry(() => fetch(edge + '/figma-compat/uui/presign', { method: 'POST', headers: headers((msg as IngestMsg).payload.anon, (msg as IngestMsg).payload.agentId), body: JSON.stringify({ projectId: (msg as IngestMsg).payload.projectId, fileName }) }), { retries: 2, backoffMs: 700 });
      const pj: any = await pres.json().catch(() => ({}));
      if (!pres.ok || pj?.ok !== true) throw new Error('presign_failed');
      const storageKey: string = pj.key;
      const signedUrl: string | undefined = pj.signedUrl;

      // 3) upload via signed url
      if (signedUrl) {
        postStatus('Uploading JSON to Storage...');
        const up = await retry(() => fetch(signedUrl!, { method: 'PUT', headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload) }), { retries: 2, backoffMs: 800 });
        if (!up.ok) throw new Error('upload_failed');
      } else {
        postStatus('No signed URL returned, assuming object exists.');
      }

      // 4) ingest request
      postStatus('Submitting ingest request...');
      const idem = 'ing-' + Date.now();
      const ingRes = await retry(() => fetch(edge + '/figma-compat/uui/ingest', { method: 'POST', headers: { ...headers((msg as IngestMsg).payload.anon, (msg as IngestMsg).payload.agentId), 'Idempotency-Key': idem }, body: JSON.stringify({ projectId: (msg as IngestMsg).payload.projectId, storage_key: storageKey }) }), { retries: 2, backoffMs: 700 });
      const ing: any = await ingRes.json().catch(() => ({}));
      if (!ingRes.ok || ing?.ok !== true) throw new Error('ingest_failed');
      const traceId: string = ing.trace_id;

      // 5) poll for result
      postStatus('Polling ingest result...');
      let ready = false; let outKey = ''; let outSigned: string | null = null;
      for (let i = 0; i < 20; i++) {
        await new Promise((r) => setTimeout(r, 1000 + i * 100));
        const r = await retry(() => fetch(edge + `/figma-compat/uui/ingest/result?traceId=${encodeURIComponent(traceId)}`, { headers: headers((msg as IngestMsg).payload.anon, (msg as IngestMsg).payload.agentId) }), { retries: 1, backoffMs: 500 });
        const j: any = await r.json().catch(() => ({}));
        if (r.ok && j?.ok && j?.status === 'ready') { ready = true; outKey = j?.key || ''; outSigned = j?.signedUrl || null; break; }
      }
      figma.ui.postMessage({ type: 'ingest_result', ok: ready, trace_id: traceId, key: outKey, signedUrl: outSigned });
    } catch (e) {
      figma.ui.postMessage({ type: 'ingest_result', ok: false, error: String((e as Error)?.message || e) });
    }
  }

  if (msg.type === 'chat_sse') {
    try {
      const base = (msg as ChatSseMsg).payload.edge.replace(/\/$/, '');
      const sessionId = (msg as ChatSseMsg).payload.sessionId || ('sess_'+Date.now());
      const body = { session_id: sessionId, text: (msg as ChatSseMsg).payload.text };
      postStatus('Connecting chat SSE...');
      await readSse(base + '/chat-gateway', {
        method: 'POST',
        headers: headers((msg as ChatSseMsg).payload.anon, (msg as ChatSseMsg).payload.agentId),
        body: JSON.stringify(body),
        onEvent: (event, data) => {
          figma.ui.postMessage({ type: 'sse_frame', source: 'chat', event, data });
        }
      });
      figma.ui.postMessage({ type: 'sse_done', source: 'chat' });
    } catch (e) {
      figma.ui.postMessage({ type: 'sse_error', source: 'chat', error: String((e as Error)?.message || e) });
    }
    return;
  }

  if (msg.type === 'context_sse') {
    try {
      const base = (msg as ContextSseMsg).payload.edge.replace(/\/$/, '');
      const body = { job_id: (msg as ContextSseMsg).payload.jobId, cursor: (msg as ContextSseMsg).payload.cursor };
      postStatus('Connecting figma-context SSE...');
      await readSse(base + '/figma-context/stream', {
        method: 'POST',
        headers: headers((msg as ContextSseMsg).payload.anon, (msg as ContextSseMsg).payload.agentId),
        body: JSON.stringify(body),
        onEvent: (event, data) => {
          figma.ui.postMessage({ type: 'sse_frame', source: 'figma-context', event, data });
        }
      });
      figma.ui.postMessage({ type: 'sse_done', source: 'figma-context' });
    } catch (e) {
      figma.ui.postMessage({ type: 'sse_error', source: 'figma-context', error: String((e as Error)?.message || e) });
    }
    return;
  }

  if (msg.type === 'uui_generate' || msg.type === 'uui_generate_llm') {
    try {
      const base = ((msg as GenerateMsg).payload.edge || '').replace(/\/$/, '');
      const path = (msg.type === 'uui_generate_llm') ? '/figma-compat/uui/generate/llm' : '/figma-compat/uui/generate';
      const cogo = (() => {
        const raw = (msg as GenerateMsg).payload.cogo || '';
        if (!raw.trim()) return undefined;
        try { return JSON.parse(raw); } catch { return undefined; }
      })();
      // Guard: projectId must be UUID if provided
      const pjId = (msg as GenerateMsg).payload.projectId;
      if (pjId && !(globalThis as any).__isUuid(pjId)) { throw new Error('Invalid projectId. Expected UUID'); }
      const body: any = { projectId: pjId, intent: { language: prefLanguage, keywords: ['ui.generate'] } };
      if (typeof (msg as GenerateMsg).payload.prompt === 'string') body.prompt = (msg as GenerateMsg).payload.prompt;
      if (cogo) body.cogo_ui_json = cogo;
      postStatus('Generating UUI/COGO...');
      const idem = 'gen-' + Date.now();
      const res = await retry(() => fetch(base + path, { method: 'POST', headers: { ...headers(((msg as any).payload.anon), ((msg as any).payload.agentId)), 'Idempotency-Key': idem }, body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
      const json = await res.json().catch(() => ({}));
      if (res.status === 413 || (json && json.error === 'payload_too_large')) {
        figma.ui.postMessage({ type: 'result', ok: false, error: 'Payload too large. Use Upload & Ingest flow.' });
        return;
      }
      figma.ui.postMessage({ type: 'result', ok: res.ok, json });
      try {
        const ih = (json && json.ide_hints) || null;
        if (ih) {
          const t = (prefLanguage || 'en').toLowerCase();
          const toast = ih[`toast_${t}`] || ih.toast || '';
          if (toast) postStatus(String(toast));
        }
      } catch {}
    } catch (e) {
      figma.ui.postMessage({ type: 'result', ok: false, error: String((e as Error)?.message || e) });
    }
    return;
  }
};


