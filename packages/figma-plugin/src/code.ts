// Figma Plugin main code
figma.showUI(__html__, { width: 520, height: 700 });

// TypeScript types for Figma plugin

type ConvertMsg = { type: 'convert'; payload: { edge: string; anon: string; projectId: string; agentId?: string } };
type IngestMsg = { type: 'ingest'; payload: { edge: string; anon: string; projectId: string; fileName?: string; json?: string; agentId?: string } };
type ChatSseMsg = { type: 'chat_sse'; payload: { edge: string; anon: string; text: string; sessionId?: string; agentId?: string } };
type ContextSseMsg = { type: 'context_sse'; payload: { edge: string; anon: string; jobId: string; cursor: number; agentId?: string } };
type GenerateMsg = { type: 'uui_generate'; payload: { edge: string; anon: string; projectId?: string; prompt?: string; cogo?: string; agentId?: string } };
type GenerateLlmMsg = { type: 'uui_generate_llm'; payload: { edge: string; anon: string; projectId?: string; prompt: string; cogo?: string; agentId?: string } };
type ResultMsg = { type: 'result'; ok: boolean; json?: any; error?: string };
type TestMsg = { type: 'test'; payload: { message: string } };

function headers(anon: string | undefined, agentId?: string) {
  const h: any = { 'content-type': 'application/json' };
  if (anon) { h['Authorization'] = `Bearer ${anon}`; h['apikey'] = anon; }
  if (agentId && agentId.trim()) { h['x-agent-id'] = agentId.trim(); }
  return h;
}

function postStatus(message: string) { figma.ui.postMessage({ type: 'status', message }); }

async function retry<T>(fn: () => Promise<T>, opts?: { retries?: number; backoffMs?: number }): Promise<T> {
  const retries = opts && opts.retries !== undefined ? opts.retries : 3;
  const back = opts && opts.backoffMs !== undefined ? opts.backoffMs : 500;
  let lastErr: any;
  for (let i = 0; i <= retries; i++) {
    try { return await fn(); } catch (e) { lastErr = e; }
    await new Promise((r) => setTimeout(r, back * Math.max(1, i)));
  }
  throw lastErr;
}

async function readSse(url: string, init: RequestInit & { onEvent?: (event: string, data: string) => void } = {}) {
  const fetchInit = Object.assign({}, init);
  const headers = Object.assign({}, init.headers || {}, { accept: 'text/event-stream' });
  fetchInit.headers = headers;
  
  const res = await fetch(url, fetchInit);
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
      try { if (init.onEvent) init.onEvent(evt, dat); } catch (e) {}
    }
  }
}

figma.ui.onmessage = async (msg: ConvertMsg | IngestMsg | ChatSseMsg | ContextSseMsg | GenerateMsg | GenerateLlmMsg | ResultMsg | TestMsg) => {
  if (msg.type === 'convert') {
  try {
    if (!figma.currentPage.selection.length) { 
      postStatus('Please select at least one node to convert');
      throw new Error('No selection. Select at least one node.'); 
    }
    
    const selectionCount = figma.currentPage.selection.length;
    postStatus(`Converting ${selectionCount} selected node${selectionCount > 1 ? 's' : ''} → UUI & Cogo...`);
    
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
    
    // Make the API call directly from plugin code
    // CORRECT - Includes /functions/v1/
    // const url = msg.payload.edge.replace(/\/$/, '') + '/figma-compat/uui/symbols/map';
    const url = msg.payload.edge.replace(/\/$/, '') + '/functions/v1/figma-compat/uui/symbols/map';
    const response = await retry(() => fetch(url, {
      method: 'POST',
      headers: headers(msg.payload.anon, msg.payload.agentId),
      body: JSON.stringify(body)
    }), { retries: 2, backoffMs: 700 });
    
    const json = await response.json();
    figma.ui.postMessage({ type: 'result', ok: response.ok, json });
    
  } catch (e) {
    console.error('Convert error:', e);
    const errorMessage = e instanceof Error ? e.message : String(e);
    postStatus(`Conversion failed: ${errorMessage}`);
    figma.ui.postMessage({ type: 'result', ok: false, error: errorMessage });
  }
  return;
}

  // Handle result messages from UI (API responses)
  if (msg.type === 'result') {
    console.log('Plugin received result:', msg);
    // The UI will handle displaying the result, so we just need to acknowledge it
    return;
  }

  if (msg.type === 'ingest') {
    const edge = msg.payload.edge.replace(/\/$/, '');
    try {
      // 1) Prepare JSON (from textarea or selection)
      postStatus('Preparing JSON...');
      let payload: any;
      if (msg.payload.json && msg.payload.json.trim()) {
        try { payload = JSON.parse(msg.payload.json); } catch (e) { throw new Error('Invalid JSON in input'); }
      } else {
        const selection = figma.currentPage.selection;
        if (!selection.length) { throw new Error('No selection and no JSON provided'); }
        const nodes = selection.map((n) => ({ type: n.type.toLowerCase(), id: n.id, name: (n as any).name || n.type }));
        payload = { cogo_ui_json: nodes };
      }

      // 2) presign
      postStatus('Requesting presign...');
      const fileName = (msg.payload.fileName && msg.payload.fileName.trim()) || `figma_${Date.now()}.json`;
      const pres = await retry(() => fetch(edge + '/functions/v1/figma-compat/uui/presign', { method: 'POST', headers: headers(msg.payload.anon, msg.payload.agentId), body: JSON.stringify({ projectId: msg.payload.projectId, fileName }) }), { retries: 2, backoffMs: 700 });
      const pj: any = await pres.json().catch(() => ({}));
      if (!pres.ok || (pj && pj.ok !== true)) throw new Error('presign_failed');
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
      const headerObj = headers(msg.payload.anon, msg.payload.agentId);
      headerObj['Idempotency-Key'] = idem;
      const ingRes = await retry(() => fetch(edge + '/functions/v1/figma-compat/uui/ingest', { method: 'POST', headers: headerObj, body: JSON.stringify({ projectId: msg.payload.projectId, storage_key: storageKey }) }), { retries: 2, backoffMs: 700 });
      const ing: any = await ingRes.json().catch(() => ({}));
      if (!ingRes.ok || (ing && ing.ok !== true)) throw new Error('ingest_failed');
      const traceId: string = ing.trace_id;

      // 5) poll for result
      postStatus('Processing ingest request...');
      let ready = false; let outKey = ''; let outSigned: string | null = null; let attempts = 0;
      for (let i = 0; i < 20; i++) {
        await new Promise((r) => setTimeout(r, 1000 + i * 100));
        attempts++;
        
        postStatus(`Checking progress... (${attempts}/20)`);
        
        const r = await retry(() => fetch(edge + `/functions/v1/figma-compat/uui/ingest/result?traceId=${encodeURIComponent(traceId)}`, { headers: headers(msg.payload.anon, msg.payload.agentId) }), { retries: 1, backoffMs: 500 });
        const j: any = await r.json().catch(() => ({}));
        if (r.ok && j && j.ok && j.status === 'ready') { 
          ready = true; 
          outKey = (j && j.key) || ''; 
          outSigned = (j && j.signedUrl) || null; 
          postStatus('Ingest completed successfully!');
          break; 
        }
      }
      
      if (!ready) {
        postStatus('Ingest timed out after 20 attempts');
      }
      figma.ui.postMessage({ type: 'ingest_result', ok: ready, trace_id: traceId, key: outKey, signedUrl: outSigned });
    } catch (e) {
      figma.ui.postMessage({ type: 'ingest_result', ok: false, error: String((e as Error && (e as Error).message) || e) });
    }
  }

  if (msg.type === 'chat_sse') {
    try {
      const base = msg.payload.edge.replace(/\/$/, '');
      const sessionId = msg.payload.sessionId || ('sess_'+Date.now());
      const body = { session_id: sessionId, text: msg.payload.text };
      postStatus('Connecting to chat service...');
      await readSse(base + '/functions/v1/chat-gateway', {
        method: 'POST',
        headers: headers(msg.payload.anon, msg.payload.agentId),
        body: JSON.stringify(body),
        onEvent: (event, data) => {
          figma.ui.postMessage({ type: 'sse_frame', source: 'chat', event, data });
        }
      });
      postStatus('Chat session completed');
      figma.ui.postMessage({ type: 'sse_done', source: 'chat' });
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      postStatus(`Chat error: ${errorMessage}`);
      figma.ui.postMessage({ type: 'sse_error', source: 'chat', error: errorMessage });
    }
    return;
  }

  if (msg.type === 'context_sse') {
    try {
      const base = msg.payload.edge.replace(/\/$/, '');
      const body = { job_id: msg.payload.jobId, cursor: msg.payload.cursor };
      postStatus('Connecting to context service...');
      await readSse(base + '/functions/v1/figma-context/stream', {
        method: 'POST',
        headers: headers(msg.payload.anon, msg.payload.agentId),
        body: JSON.stringify(body),
        onEvent: (event, data) => {
          figma.ui.postMessage({ type: 'sse_frame', source: 'figma-context', event, data });
        }
      });
      postStatus('Context stream completed');
      figma.ui.postMessage({ type: 'sse_done', source: 'figma-context' });
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      postStatus(`Context error: ${errorMessage}`);
      figma.ui.postMessage({ type: 'sse_error', source: 'figma-context', error: errorMessage });
    }
    return;
  }

  if (msg.type === 'uui_generate' || msg.type === 'uui_generate_llm') {
    try {
      const base = (msg.payload.edge || '').replace(/\/$/, '');
      const path = (msg.type === 'uui_generate_llm') ? '/functions/v1/figma-compat/uui/generate/llm' : '/functions/v1/figma-compat/uui/generate';
      const cogo = (() => {
        const raw = msg.payload.cogo || '';
        if (!raw.trim()) return undefined;
        try { return JSON.parse(raw); } catch (e) { return undefined; }
      })(); 
      const body: any = { projectId: msg.payload.projectId };
      if (typeof msg.payload.prompt === 'string') body.prompt = msg.payload.prompt;
      if (cogo) body.cogo_ui_json = cogo;
      postStatus('Generating UUI/COGO...');
      const res = await retry(() => fetch(base + path, { method: 'POST', headers: headers((msg as any).payload.anon, (msg as any).payload.agentId), body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
      const json = await res.json().catch(() => ({}));
      figma.ui.postMessage({ type: 'result', ok: res.ok, json });
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      postStatus(`Generation error: ${errorMessage}`);
      figma.ui.postMessage({ type: 'result', ok: false, error: errorMessage });
    }
    return;
  }

  if (msg.type === 'test') {
    console.log('Plugin received test message:', msg.payload.message);
    figma.ui.postMessage({ type: 'test_result', message: `Received test message: ${msg.payload.message}` });
    return;
  }
};


