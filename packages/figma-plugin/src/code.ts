// Figma Plugin main code
figma.showUI(__html__, { width: 520, height: 700 });

import type { } from 'typescript';

type ConvertMsg = { type: 'convert'; payload: { edge: string; anon: string; projectId: string; agentId?: string } };
type IngestMsg = { type: 'ingest'; payload: { edge: string; anon: string; projectId: string; fileName?: string; json?: string; agentId?: string } };
type ChatSseMsg = { type: 'chat_sse'; payload: { edge: string; anon: string; text: string; sessionId?: string; agentId?: string } };
type ContextSseMsg = { type: 'context_sse'; payload: { edge: string; anon: string; jobId: string; cursor: number; agentId?: string } };
type GenerateMsg = { type: 'uui_generate'; payload: { edge: string; anon: string; projectId?: string; prompt?: string; cogo?: string; agentId?: string } };
type GenerateLlmMsg = { type: 'uui_generate_llm'; payload: { edge: string; anon: string; projectId?: string; prompt: string; cogo?: string; agentId?: string } };

function headers(anon: string | undefined, agentId?: string) {
  const h: any = { 'content-type': 'application/json' };
  if (anon) { h['Authorization'] = `Bearer ${anon}`; h['apikey'] = anon; }
  if (agentId && agentId.trim()) { h['x-agent-id'] = agentId.trim(); }
  return h;
}

function postStatus(message: string) { figma.ui.postMessage({ type: 'status', message }); }

async function retry<T>(fn: () => Promise<T>, opts?: { retries?: number; backoffMs?: number }): Promise<T> {
  const retries = opts?.retries ?? 3;
  const back = opts?.backoffMs ?? 500;
  let lastErr: any;
  for (let i = 0; i <= retries; i++) {
    try { return await fn(); } catch (e) { lastErr = e; }
    await new Promise((r) => setTimeout(r, back * Math.max(1, i)));
  }
  throw lastErr;
}

async function readSse(url: string, init: RequestInit & { onEvent?: (event: string, data: string) => void } = {}) {
  const res = await fetch(url, { ...init, headers: { ...(init.headers||{}), accept: 'text/event-stream' } as any });
  if (!res.ok || !(res as any).body) throw new Error(`sse_failed_${res.status}`);
  const reader = (res as any).body.getReader();
  const decoder = new TextDecoder();
  let buf = '';
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buf += decoder.decode(value, { stream: true });
    let idx: number;
    while ((idx = buf.indexOf('\n\n')) >= 0) {
      const frame = buf.slice(0, idx); buf = buf.slice(idx + 2);
      const lines = frame.split('\n');
      const evt = (lines.find(l => l.startsWith('event:')) || '').replace(/^event:\s*/, '').trim();
      const dat = (lines.find(l => l.startsWith('data:')) || '').replace(/^data:\s*/, '');
      try { init.onEvent && init.onEvent(evt, dat); } catch {}
    }
  }
}

figma.ui.onmessage = async (msg: ConvertMsg | IngestMsg | ChatSseMsg | ContextSseMsg | GenerateMsg | GenerateLlmMsg) => {
  if (msg.type === 'convert') {
    try {
      // Guard: require selection
      if (!figma.currentPage.selection.length) { throw new Error('No selection. Select at least one node.'); }
      postStatus('Converting selection → UUI & Cogo...');
      const selection = figma.currentPage.selection;
      const nodes = selection.map((n) => ({ type: n.type.toLowerCase(), id: n.id, name: (n as any).name || n.type }));
      const body = {
        user_id: 'figma-plugin',
        session_id: 'sess_' + Date.now(),
        projectId: msg.payload.projectId,
        page_id: 1,
        page_name: figma.currentPage.name,
        cogo_ui_json: nodes
      };
      const res = await retry(() => fetch(msg.payload.edge.replace(/\/$/,'') + '/figma-compat/uui/symbols/map', { method: 'POST', headers: headers(msg.payload.anon, msg.payload.agentId), body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
      const json = await res.json();
      figma.ui.postMessage({ type: 'result', ok: res.ok, json });
    } catch (e) {
      figma.ui.postMessage({ type: 'result', ok: false, error: String((e as Error)?.message || e) });
    }
    return;
  }

  if (msg.type === 'ingest') {
    const edge = msg.payload.edge.replace(/\/$/, '');
    try {
      // 1) Prepare JSON (from textarea or selection)
      postStatus('Preparing JSON...');
      let payload: any;
      if (msg.payload.json && msg.payload.json.trim()) {
        try { payload = JSON.parse(msg.payload.json); } catch { throw new Error('Invalid JSON in input'); }
      } else {
        const selection = figma.currentPage.selection;
        if (!selection.length) { throw new Error('No selection and no JSON provided'); }
        const nodes = selection.map((n) => ({ type: n.type.toLowerCase(), id: n.id, name: (n as any).name || n.type }));
        payload = { cogo_ui_json: nodes };
      }

      // 2) presign
      postStatus('Requesting presign...');
      const fileName = (msg.payload.fileName && msg.payload.fileName.trim()) || `figma_${Date.now()}.json`;
      const pres = await retry(() => fetch(edge + '/figma-compat/uui/presign', { method: 'POST', headers: headers(msg.payload.anon, msg.payload.agentId), body: JSON.stringify({ projectId: msg.payload.projectId, fileName }) }), { retries: 2, backoffMs: 700 });
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
      const ingRes = await retry(() => fetch(edge + '/figma-compat/uui/ingest', { method: 'POST', headers: { ...headers(msg.payload.anon, msg.payload.agentId), 'Idempotency-Key': idem }, body: JSON.stringify({ projectId: msg.payload.projectId, storage_key: storageKey }) }), { retries: 2, backoffMs: 700 });
      const ing: any = await ingRes.json().catch(() => ({}));
      if (!ingRes.ok || ing?.ok !== true) throw new Error('ingest_failed');
      const traceId: string = ing.trace_id;

      // 5) poll for result
      postStatus('Polling ingest result...');
      let ready = false; let outKey = ''; let outSigned: string | null = null; let attempts = 0;
      for (let i = 0; i < 20; i++) {
        await new Promise((r) => setTimeout(r, 1000 + i * 100));
        attempts++;
        const r = await retry(() => fetch(edge + `/figma-compat/uui/ingest/result?traceId=${encodeURIComponent(traceId)}`, { headers: headers(msg.payload.anon, msg.payload.agentId) }), { retries: 1, backoffMs: 500 });
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
      const base = msg.payload.edge.replace(/\/$/, '');
      const sessionId = msg.payload.sessionId || ('sess_'+Date.now());
      const body = { session_id: sessionId, text: msg.payload.text };
      postStatus('Connecting chat SSE...');
      await readSse(base + '/chat-gateway', {
        method: 'POST',
        headers: headers(msg.payload.anon, msg.payload.agentId),
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
      const base = msg.payload.edge.replace(/\/$/, '');
      const body = { job_id: msg.payload.jobId, cursor: msg.payload.cursor };
      postStatus('Connecting figma-context SSE...');
      await readSse(base + '/figma-context/stream', {
        method: 'POST',
        headers: headers(msg.payload.anon, msg.payload.agentId),
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
      const base = (msg.payload.edge || '').replace(/\/$/, '');
      const path = (msg.type === 'uui_generate_llm') ? '/figma-compat/uui/generate/llm' : '/figma-compat/uui/generate';
      const cogo = (() => {
        const raw = msg.payload.cogo || '';
        if (!raw.trim()) return undefined;
        try { return JSON.parse(raw); } catch { return undefined; }
      })();
      const body: any = { projectId: msg.payload.projectId };
      if (typeof msg.payload.prompt === 'string') body.prompt = msg.payload.prompt;
      if (cogo) body.cogo_ui_json = cogo;
      postStatus('Generating UUI/COGO...');
      const res = await retry(() => fetch(base + path, { method: 'POST', headers: headers((msg as any).payload.anon, (msg as any).payload.agentId), body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
      const json = await res.json().catch(() => ({}));
      figma.ui.postMessage({ type: 'result', ok: res.ok, json });
    } catch (e) {
      figma.ui.postMessage({ type: 'result', ok: false, error: String((e as Error)?.message || e) });
    }
    return;
  }
};


