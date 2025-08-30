(() => {
  var __defProp = Object.defineProperty;
  var __defProps = Object.defineProperties;
  var __getOwnPropDescs = Object.getOwnPropertyDescriptors;
  var __getOwnPropSymbols = Object.getOwnPropertySymbols;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __propIsEnum = Object.prototype.propertyIsEnumerable;
  var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
  var __spreadValues = (a, b) => {
    for (var prop in b || (b = {}))
      if (__hasOwnProp.call(b, prop))
        __defNormalProp(a, prop, b[prop]);
    if (__getOwnPropSymbols)
      for (var prop of __getOwnPropSymbols(b)) {
        if (__propIsEnum.call(b, prop))
          __defNormalProp(a, prop, b[prop]);
      }
    return a;
  };
  var __spreadProps = (a, b) => __defProps(a, __getOwnPropDescs(b));

  // src/code.ts
  figma.showUI(__html__, { width: 520, height: 700 });
  function headers(anon, agentId) {
    const h = { "content-type": "application/json" };
    if (anon) {
      h["Authorization"] = "Bearer " + anon;
      h["apikey"] = anon;
    }
    if (agentId && agentId.trim()) {
      h["x-agent-id"] = agentId.trim();
    }
    return h;
  }
  function postStatus(message) {
    figma.ui.postMessage({ type: "status", message });
  }
  async function retry(fn, opts) {
    const retries = opts && typeof opts.retries === "number" ? opts.retries : 3;
    const back = opts && typeof opts.backoffMs === "number" ? opts.backoffMs : 500;
    let lastErr;
    for (let i = 0; i <= retries; i++) {
      try {
        return await fn();
      } catch (e) {
        lastErr = e;
      }
      await new Promise((r) => setTimeout(r, back * Math.max(1, i)));
    }
    throw lastErr;
  }
  async function readSse(url, init = {}) {
    const baseHeaders = init.headers || {};
    baseHeaders["accept"] = "text/event-stream";
    const res = await fetch(url, { method: init.method || "POST", headers: baseHeaders, body: init.body, signal: init.signal });
    if (!res.ok || !res.body) throw new Error("sse_failed_" + res.status);
    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buf = "";
    while (true) {
      const r = await reader.read();
      const value = r.value;
      const done = r.done;
      if (done) break;
      buf += decoder.decode(value, { stream: true });
      let idx;
      while ((idx = buf.indexOf("\n\n")) >= 0) {
        const frame = buf.slice(0, idx);
        buf = buf.slice(idx + 2);
        const lines = frame.split("\n");
        let evt = "";
        let dat = "";
        for (const line of lines) {
          if (line.indexOf("event:") === 0) evt = line.replace(/^event:\s*/, "").trim();
          if (line.indexOf("data:") === 0) dat = line.replace(/^data:\s*/, "");
        }
        try {
          if (init.onEvent) init.onEvent(evt, dat);
        } catch (e) {
        }
      }
    }
  }
  var presenceSessionId = "";
  var heartbeatTimer = null;
  var persistentPluginId = "";
  function uuid() {
    try {
      return crypto.randomUUID();
    } catch (e) {
      return Date.now() + "-" + Math.random().toString(16).slice(2);
    }
  }
  (async () => {
    try {
      const saved = await figma.clientStorage.getAsync("plugin_id");
      if (typeof saved === "string" && saved.trim()) {
        persistentPluginId = saved.trim();
      } else {
        persistentPluginId = "fp-" + uuid();
        await figma.clientStorage.setAsync("plugin_id", persistentPluginId);
      }
      figma.ui.postMessage({ type: "presence", ok: true, session_id: persistentPluginId });
    } catch (e) {
    }
  })();
  async function presenceRegister(edge, anon, projectId, fileKey, userId, ttlMs, agentId) {
    const body = { plugin_id: presenceSessionId || persistentPluginId };
    if (projectId) body.project_id = projectId;
    try {
      if (!fileKey && figma.fileKey) fileKey = String(figma.fileKey || "");
    } catch (e) {
    }
    if (fileKey) body.file_key = fileKey;
    if (userId) body.user_id = userId;
    body.ttl_ms = typeof ttlMs === "number" && ttlMs > 0 ? ttlMs : 6e4;
    const res = await retry(() => fetch(edge.replace(/\/$/, "") + "/figma-plugin/presence/register", { method: "POST", headers: headers(anon, agentId), body: JSON.stringify(body) }));
    const j = await res.json();
    if (!res.ok || !j || !j.ok) throw new Error("presence_register_failed");
    presenceSessionId = String(j.session_id || "");
    const hbMs = Number(j.heartbeat_ms || 15e3);
    if (heartbeatTimer) clearInterval(heartbeatTimer);
    heartbeatTimer = setInterval(async () => {
      try {
        await fetch(edge.replace(/\/$/, "") + "/figma-plugin/presence/heartbeat", { method: "POST", headers: headers(anon, agentId), body: JSON.stringify({ session_id: presenceSessionId }) });
      } catch (e) {
      }
    }, hbMs);
    figma.ui.postMessage({ type: "presence", ok: true, session_id: presenceSessionId });
  }
  async function presenceUnregister(edge, anon, agentId) {
    if (!presenceSessionId) return;
    try {
      await fetch(edge.replace(/\/$/, "") + "/figma-plugin/presence/unregister", { method: "POST", headers: headers(anon, agentId), body: JSON.stringify({ session_id: presenceSessionId }) });
    } catch (e) {
    }
    try {
      clearInterval(heartbeatTimer);
    } catch (e) {
    }
    heartbeatTimer = null;
    presenceSessionId = "";
  }
  figma.on("close", () => {
    presenceSessionId = "";
    try {
      clearInterval(heartbeatTimer);
    } catch (e) {
    }
  });
  figma.ui.onmessage = async (msg) => {
    if (msg.type === "presence_register") {
      try {
        const p = msg.payload;
        await presenceRegister(p.edge, p.anon, p.projectId, p.fileKey, p.userId, p.ttlMs, p.agentId);
      } catch (e) {
        figma.ui.postMessage({ type: "presence", ok: false, error: String(e.message || e) });
      }
      return;
    }
    if (msg.type === "presence_unregister") {
      try {
        const p = msg.payload;
        await presenceUnregister(p.edge, p.anon, p.agentId);
        figma.ui.postMessage({ type: "presence", ok: true, unregistered: true });
      } catch (e) {
      }
      return;
    }
    if (msg.type === "context_start") {
      try {
        const p = msg.payload;
        const base = p.edge.replace(/\/$/, "");
        let figmaUrl = (p.figmaUrl || "").trim();
        if (!figmaUrl) {
          let fk = "";
          try {
            fk = String(figma.fileKey || "");
          } catch (e) {
          }
          const sel = figma.currentPage.selection;
          const nodeId = sel && sel.length > 0 ? String(sel[0].id || "") : "";
          if (fk && nodeId) figmaUrl = "https://www.figma.com/file/" + fk + "?node-id=" + encodeURIComponent(nodeId);
        }
        if (!figmaUrl) throw new Error("figma_url_required");
        const res = await retry(() => fetch(base + "/figma-context/start", { method: "POST", headers: headers(p.anon, p.agentId), body: JSON.stringify({ figma_url: figmaUrl }) }), { retries: 2, backoffMs: 700 });
        const j = await res.json();
        figma.ui.postMessage({ type: "context_start_result", ok: res.ok, json: j });
      } catch (e) {
        figma.ui.postMessage({ type: "context_start_result", ok: false, error: String(e.message || e) });
      }
      return;
    }
    if (msg.type === "context_apply") {
      try {
        const p = msg.payload;
        const base = p.edge.replace(/\/$/, "");
        const body = { job_id: p.jobId, projectId: p.projectId };
        if (typeof p.pageId === "number") body.page_id = p.pageId;
        const res = await retry(() => fetch(base + "/figma-context/apply", { method: "POST", headers: headers(p.anon, p.agentId), body: JSON.stringify(body) }), { retries: 1, backoffMs: 500 });
        const j = await res.json();
        figma.ui.postMessage({ type: "context_apply_result", ok: res.ok, json: j });
      } catch (e) {
        figma.ui.postMessage({ type: "context_apply_result", ok: false, error: String(e.message || e) });
      }
      return;
    }
    if (msg.type === "convert") {
      try {
        if (!figma.currentPage.selection.length) {
          throw new Error("No selection. Select at least one node.");
        }
        postStatus("Converting selection \u2192 UUI & Cogo...");
        const selection = figma.currentPage.selection;
        const nodes = selection.map((n) => ({ type: n.type.toLowerCase(), id: n.id, name: n.name || n.type }));
        const body = {
          user_id: "figma-plugin",
          session_id: "sess_" + Date.now(),
          projectId: msg.payload.projectId,
          page_id: 1,
          page_name: figma.currentPage.name,
          cogo_ui_json: nodes
        };
        const res = await retry(() => fetch(msg.payload.edge.replace(/\/$/, "") + "/figma-compat/uui/symbols/map", { method: "POST", headers: headers(msg.payload.anon, msg.payload.agentId), body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
        const json = await res.json();
        figma.ui.postMessage({ type: "result", ok: res.ok, json });
      } catch (e) {
        figma.ui.postMessage({ type: "result", ok: false, error: String((e == null ? void 0 : e.message) || e) });
      }
      return;
    }
    if (msg.type === "ingest") {
      const edge = msg.payload.edge.replace(/\/$/, "");
      try {
        postStatus("Preparing JSON...");
        let payload;
        if (msg.payload.json && msg.payload.json.trim()) {
          try {
            payload = JSON.parse(msg.payload.json);
          } catch (e) {
            throw new Error("Invalid JSON in input");
          }
        } else {
          const selection = figma.currentPage.selection;
          if (!selection.length) {
            throw new Error("No selection and no JSON provided");
          }
          const nodes = selection.map((n) => ({ type: n.type.toLowerCase(), id: n.id, name: n.name || n.type }));
          payload = { cogo_ui_json: nodes };
        }
        postStatus("Requesting presign...");
        const fileName = msg.payload.fileName && msg.payload.fileName.trim() || `figma_${Date.now()}.json`;
        const pres = await retry(() => fetch(edge + "/figma-compat/uui/presign", { method: "POST", headers: headers(msg.payload.anon, msg.payload.agentId), body: JSON.stringify({ projectId: msg.payload.projectId, fileName }) }), { retries: 2, backoffMs: 700 });
        const pj = await pres.json().catch(() => ({}));
        if (!pres.ok || (pj == null ? void 0 : pj.ok) !== true) throw new Error("presign_failed");
        const storageKey = pj.key;
        const signedUrl = pj.signedUrl;
        if (signedUrl) {
          postStatus("Uploading JSON to Storage...");
          const up = await retry(() => fetch(signedUrl, { method: "PUT", headers: { "content-type": "application/json" }, body: JSON.stringify(payload) }), { retries: 2, backoffMs: 800 });
          if (!up.ok) throw new Error("upload_failed");
        } else {
          postStatus("No signed URL returned, assuming object exists.");
        }
        postStatus("Submitting ingest request...");
        const idem = "ing-" + Date.now();
        const ingRes = await retry(() => fetch(edge + "/figma-compat/uui/ingest", { method: "POST", headers: __spreadProps(__spreadValues({}, headers(msg.payload.anon, msg.payload.agentId)), { "Idempotency-Key": idem }), body: JSON.stringify({ projectId: msg.payload.projectId, storage_key: storageKey }) }), { retries: 2, backoffMs: 700 });
        const ing = await ingRes.json().catch(() => ({}));
        if (!ingRes.ok || (ing == null ? void 0 : ing.ok) !== true) throw new Error("ingest_failed");
        const traceId = ing.trace_id;
        postStatus("Polling ingest result...");
        let ready = false;
        let outKey = "";
        let outSigned = null;
        for (let i = 0; i < 20; i++) {
          await new Promise((r2) => setTimeout(r2, 1e3 + i * 100));
          const r = await retry(() => fetch(edge + `/figma-compat/uui/ingest/result?traceId=${encodeURIComponent(traceId)}`, { headers: headers(msg.payload.anon, msg.payload.agentId) }), { retries: 1, backoffMs: 500 });
          const j = await r.json().catch(() => ({}));
          if (r.ok && (j == null ? void 0 : j.ok) && (j == null ? void 0 : j.status) === "ready") {
            ready = true;
            outKey = (j == null ? void 0 : j.key) || "";
            outSigned = (j == null ? void 0 : j.signedUrl) || null;
            break;
          }
        }
        figma.ui.postMessage({ type: "ingest_result", ok: ready, trace_id: traceId, key: outKey, signedUrl: outSigned });
      } catch (e) {
        figma.ui.postMessage({ type: "ingest_result", ok: false, error: String((e == null ? void 0 : e.message) || e) });
      }
    }
    if (msg.type === "chat_sse") {
      try {
        const base = msg.payload.edge.replace(/\/$/, "");
        const sessionId = msg.payload.sessionId || "sess_" + Date.now();
        const body = { session_id: sessionId, text: msg.payload.text };
        postStatus("Connecting chat SSE...");
        await readSse(base + "/chat-gateway", {
          method: "POST",
          headers: headers(msg.payload.anon, msg.payload.agentId),
          body: JSON.stringify(body),
          onEvent: (event, data) => {
            figma.ui.postMessage({ type: "sse_frame", source: "chat", event, data });
          }
        });
        figma.ui.postMessage({ type: "sse_done", source: "chat" });
      } catch (e) {
        figma.ui.postMessage({ type: "sse_error", source: "chat", error: String((e == null ? void 0 : e.message) || e) });
      }
      return;
    }
    if (msg.type === "context_sse") {
      try {
        const base = msg.payload.edge.replace(/\/$/, "");
        const body = { job_id: msg.payload.jobId, cursor: msg.payload.cursor };
        postStatus("Connecting figma-context SSE...");
        await readSse(base + "/figma-context/stream", {
          method: "POST",
          headers: headers(msg.payload.anon, msg.payload.agentId),
          body: JSON.stringify(body),
          onEvent: (event, data) => {
            figma.ui.postMessage({ type: "sse_frame", source: "figma-context", event, data });
          }
        });
        figma.ui.postMessage({ type: "sse_done", source: "figma-context" });
      } catch (e) {
        figma.ui.postMessage({ type: "sse_error", source: "figma-context", error: String((e == null ? void 0 : e.message) || e) });
      }
      return;
    }
    if (msg.type === "uui_generate" || msg.type === "uui_generate_llm") {
      try {
        const base = (msg.payload.edge || "").replace(/\/$/, "");
        const path = msg.type === "uui_generate_llm" ? "/figma-compat/uui/generate/llm" : "/figma-compat/uui/generate";
        const cogo = (() => {
          const raw = msg.payload.cogo || "";
          if (!raw.trim()) return void 0;
          try {
            return JSON.parse(raw);
          } catch (e) {
            return void 0;
          }
        })();
        const body = { projectId: msg.payload.projectId };
        if (typeof msg.payload.prompt === "string") body.prompt = msg.payload.prompt;
        if (cogo) body.cogo_ui_json = cogo;
        postStatus("Generating UUI/COGO...");
        const res = await retry(() => fetch(base + path, { method: "POST", headers: headers(msg.payload.anon, msg.payload.agentId), body: JSON.stringify(body) }), { retries: 2, backoffMs: 700 });
        const json = await res.json().catch(() => ({}));
        figma.ui.postMessage({ type: "result", ok: res.ok, json });
      } catch (e) {
        figma.ui.postMessage({ type: "result", ok: false, error: String((e == null ? void 0 : e.message) || e) });
      }
      return;
    }
  };
})();
