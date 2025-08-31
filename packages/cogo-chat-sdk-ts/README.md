# COGO Chat SDK

TypeScript client for COGO chat protocol using Supabase Edge functions.

## Install
```
npm i @cogo/cogo-chat-sdk-ts @supabase/supabase-js
```

## Quick Start
```ts
import { createCogoClient } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({
  edgeBase: `https://${process.env.SUPABASE_PROJECT_ID}.functions.supabase.co/functions/v1`,
  anonKey: process.env.SUPABASE_ANON_KEY!,
});

const caps = await client.getCapabilities();
console.log(caps.editor_context_support, caps.sse_events);
```

## Streaming example
```ts
import { createCogoClient } from '@cogo/cogo-chat-sdk-ts';
import { ChatEndpoints } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const api = new ChatEndpoints(client);

await api.streamDesignGenerate(
  { text: 'Create login UI', dev_cli_simulate: true },
  (event, data) => { console.log('event:', event, 'data:', data); }
);
```

### Abort example (development)
```ts
import { createCogoClient, ChatEndpoints } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const api = new ChatEndpoints(client);

const ctrl = new AbortController();
// server-side dev abort frame after 200ms (if supported)
api.streamDesignGenerate({ text: 'Create UI', dev_abort_after_ms: 200 }, (e, d) => console.log(e, d), { signal: ctrl.signal });
// or client-side cancel
setTimeout(() => ctrl.abort(), 100);
```

### Close semantics (explicit client close recommended)
```ts
import { createCogoClient, ChatEndpoints } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const api = new ChatEndpoints(client);

const ctrl = new AbortController();
try {
  await api.streamDesignGenerate({ text: 'Create UI', dev_cli_simulate: true }, (event, data) => {
    // handle frames ...
    if (event === 'done' || event === 'error') {
      try { ctrl.abort(); } catch {}
    }
  }, { signal: ctrl.signal });
} catch (e: any) {
  const name = (e?.name || '');
  const msg = String(e?.message || e || '');
  // AbortError is expected when client closes stream intentionally
  if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
}
```

## Typed SSE and CLI aggregation
```ts
import { createCogoClient, ChatEndpoints, streamTyped, aggregateCli } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const api = new ChatEndpoints(client);
const url = `${client.baseUrl()}/design-generate`;
const agg = aggregateCli();

await streamTyped(url, { 'content-type': 'application/json', ...client.headers() }, { text: 'Create login UI', dev_cli_simulate: true }, {
  handlers: {
    meta: (m) => console.log('meta', m.trace_id),
    'cli.plan': (v) => agg.onPlan(v),
    'cli.apply': (v) => { agg.onApply(v); console.log('apply snapshot', agg.snapshot()); },
    done: (d) => console.log('done', d.trace_id),
    error: (e) => console.error('error', e)
  }
});
```

### Typed SSE with explicit close
```ts
import { createCogoClient, streamTyped, aggregateCli } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const url = `${client.baseUrl()}/design-generate`;
const agg = aggregateCli();
const ctrl = new AbortController();

try {
  await streamTyped(url, { 'content-type': 'application/json', ...client.headers() }, { text: 'Create login UI', dev_cli_simulate: true }, {
    signal: ctrl.signal,
    handlers: {
      'cli.plan': (v) => agg.onPlan(v),
      'cli.apply': (v) => agg.onApply(v),
      done: () => { console.log('[summary]', agg.snapshot()); try { ctrl.abort(); } catch {} },
      error: () => { try { ctrl.abort(); } catch {} }
    }
  });
} catch (e: any) {
  const name = (e?.name || '');
  const msg = String(e?.message || e || '');
  if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
}
```

## Hybrid: SSE first, Realtime handoff (queued/handoff)
```ts
import { createCogoClient, streamOrRealtime, createSupabaseTraceSubscriber } from '@cogo/cogo-chat-sdk-ts';
import { createClient } from '@supabase/supabase-js';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const supa = createClient(process.env.SUPABASE_URL!, process.env.ANON!, { auth: { persistSession: false } });
const subscribeTrace = createSupabaseTraceSubscriber(supa);

const url = `${client.baseUrl()}/design-generate`;
await streamOrRealtime(url, { 'content-type': 'application/json', ...client.headers() }, {
  text: 'Create login UI',
  dev_queue_sim: true,
  dev_handoff_after_ms: 200
}, {
  subscribeTrace,
  handlers: {
    meta: (m) => console.log('meta', m.trace_id),
    queued: (q) => console.log('queued', q.trace_id),
    handoff: (h) => console.log('handoff', h.trace_id),
    done: (d) => console.log('done', d.trace_id),
    error: (e) => console.error('error', e),
    fallback: (ev, raw) => console.log('ev', ev, raw)
  }
});
```

Notes:
- The SDK internally closes SSE on `done`/`error`. For robustness, you may also abort via your own `AbortController` on those frames.
- Realtime subscriber factory must return `Promise<() => Promise<void>>` and the SDK awaits unsubscribe to clean up.

## Idempotency + explicit close
```ts
import { createCogoClient, ChatEndpoints, newIdempotencyKey } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const api = new ChatEndpoints(client);
const idem = newIdempotencyKey('demo');

const ctrl = new AbortController();
try {
  await api.streamDesignGenerate({ text: 'Create login UI' }, (event) => {
    if (event === 'done' || event === 'error') { try { ctrl.abort(); } catch {} }
  }, { idempotency_key: idem, signal: ctrl.signal });
} catch (e: any) {
  const name = (e?.name || '');
  const msg = String(e?.message || e || '');
  if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
}
```

## Status polling fallback
```ts
// When Realtime is unavailable, poll status by trace_id
const url = `${process.env.EDGE_BASE}/trace-status?trace_id=${encodeURIComponent(traceId)}`;
const res = await fetch(url, { headers: { apikey: process.env.ANON!, Authorization: `Bearer ${process.env.ANON!}` } });
const js = await res.json(); // { ok, trace_id, status: 'pending'|'queued'|'handoff'|'done'|'error', events: [...] }
```
## Supabase helper
```ts
import { createSupabaseClient } from '@cogo/cogo-chat-sdk-ts';

const supa = createSupabaseClient({
  url: process.env.SUPABASE_URL!,
  key: process.env.SUPABASE_ANON_KEY!,
});
// use supa.storage.from('artifacts')...
```

## Editor context helper
```ts
import { buildEditorContext } from '@cogo/cogo-chat-sdk-ts';

const editor_context = buildEditorContext({
  openFiles: ['app/pages/login.json'],
  activeFile: 'app/pages/login.json',
  selection: { path: 'app/pages/login.json', range: [5, 15] }
});
```

## Artifacts (download/head)
```ts
import { head, downloadJson } from '@cogo/cogo-chat-sdk-ts';
// Using signedUrl from ingest/result
const meta = await head(signedUrl);
const content = await downloadJson(signedUrl);
```

Note:
- Ingest result returns `{ bucket, key, signedUrl }` and `key` is bucket-relative. When constructing manual URLs or storage APIs, join as `bucket + '/' + key`. Prefer using the provided `signedUrl` for direct download.

## IDE Hints helper (multi-language toast)
```ts
import { selectToast } from '@cogo/cogo-chat-sdk-ts';

// given `resp.ide_hints` from edge response
const toast = selectToast(resp.ide_hints, 'en'); // 'ko' | 'ja' | 'ru' | 'th'
if (toast) {
  console.log('toast:', toast.title, toast.message);
}
```
## Attachments (presign → PUT → ingest → result)
```ts
import { createCogoClient } from '@cogo/cogo-chat-sdk-ts';
import { ChatEndpoints } from '@cogo/cogo-chat-sdk-ts';

const client = createCogoClient({ edgeBase: process.env.EDGE_BASE!, anonKey: process.env.ANON! });
const api = new ChatEndpoints(client);

// 1) presign
const pres = await api.attachmentsPresign({ projectId: 'demo', fileName: 'sample.json' });
// 2) upload
await fetch(pres.signedUrl, { method: 'PUT', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ hello: 'world' }) });
// 3) ingest
const ing = await api.attachmentsIngest({ projectId: 'demo', storage_key: pres.key });
// 4) result
const res = await api.attachmentsResult(ing.trace_id);
console.log(res);
```
