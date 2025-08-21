// Figma Plugin main code
figma.showUI(__html__, { width: 420, height: 520 });

type PostMessage = { type: 'convert'; payload: { edge: string; anon: string; projectId: string } };

figma.ui.onmessage = async (msg: PostMessage) => {
  if (msg.type !== 'convert') return;
  try {
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
    const headers: any = { 'content-type': 'application/json' };
    if (msg.payload.anon) { headers['Authorization'] = `Bearer ${msg.payload.anon}`; headers['apikey'] = msg.payload.anon; }
    const res = await fetch(msg.payload.edge.replace(/\/$/,'') + '/figma-compat/uui/symbols/map', { method: 'POST', headers, body: JSON.stringify(body) });
    const json = await res.json();
    figma.ui.postMessage({ type: 'result', ok: res.ok, json });
  } catch (e) {
    figma.ui.postMessage({ type: 'result', ok: false, error: String((e as Error)?.message || e) });
  }
};


