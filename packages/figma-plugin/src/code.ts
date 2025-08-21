// Figma Plugin main code
figma.showUI(__html__, { width: 520, height: 700 });

type ConvertMsg = { type: 'convert'; payload: { edge: string; anon: string; projectId: string } };
type IngestMsg = { type: 'ingest'; payload: { edge: string; anon: string; projectId: string; fileName?: string; json?: string } };

function headers(anon: string | undefined) {
  const h: any = { 'content-type': 'application/json' };
  if (anon) { h['Authorization'] = `Bearer ${anon}`; h['apikey'] = anon; }
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

figma.ui.onmessage = async (msg: ConvertMsg | IngestMsg) => {
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
        creatego_json: nodes
      };
      const res = await retry(() => fetch(msg.payload.edge.replace(/\/$/,'') + '/figma-compat/uui/symbols/map', { method: 'POST', headers: headers(msg.payload.anon), body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
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
        payload = { creatego_json: nodes };
      }

      // 2) presign
      postStatus('Requesting presign...');
      const fileName = (msg.payload.fileName && msg.payload.fileName.trim()) || `figma_${Date.now()}.json`;
      const pres = await retry(() => fetch(edge + '/figma-compat/uui/presign', { method: 'POST', headers: headers(msg.payload.anon), body: JSON.stringify({ projectId: msg.payload.projectId, fileName }) }), { retries: 2, backoffMs: 700 });
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
      const ingRes = await retry(() => fetch(edge + '/figma-compat/uui/ingest', { method: 'POST', headers: { ...headers(msg.payload.anon), 'Idempotency-Key': idem }, body: JSON.stringify({ projectId: msg.payload.projectId, storage_key: storageKey }) }), { retries: 2, backoffMs: 700 });
      const ing: any = await ingRes.json().catch(() => ({}));
      if (!ingRes.ok || ing?.ok !== true) throw new Error('ingest_failed');
      const traceId: string = ing.trace_id;

      // 5) poll for result
      postStatus('Polling ingest result...');
      let ready = false; let outKey = ''; let outSigned: string | null = null; let attempts = 0;
      for (let i = 0; i < 20; i++) {
        await new Promise((r) => setTimeout(r, 1000 + i * 100));
        attempts++;
        const r = await retry(() => fetch(edge + `/figma-compat/uui/ingest/result?traceId=${encodeURIComponent(traceId)}`, { headers: headers(msg.payload.anon) }), { retries: 1, backoffMs: 500 });
        const j: any = await r.json().catch(() => ({}));
        if (r.ok && j?.ok && j?.status === 'ready') { ready = true; outKey = j?.key || ''; outSigned = j?.signedUrl || null; break; }
      }
      figma.ui.postMessage({ type: 'ingest_result', ok: ready, trace_id: traceId, key: outKey, signedUrl: outSigned });
    } catch (e) {
      figma.ui.postMessage({ type: 'ingest_result', ok: false, error: String((e as Error)?.message || e) });
    }
  }
};


