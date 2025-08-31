# COGO Chat SDK (Flutter) - Scaffold

This is the scaffold for the Flutter/Dart SDK for integrating with COGO chat protocol over Supabase Edge functions.

## Goals
- Provide Dart/Flutter client mirroring the TypeScript SDK capabilities.
- Typed models for envelope/capabilities/intent/cli_actions/attachments.
- SSE support via `EventSource`-like stream parsing and cancellation.

## Package Structure (proposed)
- lib/
  - cogo_chat_client.dart
  - endpoints/
    - capabilities.dart
    - design_generate.dart
    - figma_context.dart
    - compat/
      - variables_derive.dart
      - symbols_map.dart
    - bdd.dart
    - actionflow.dart
    - data_action.dart
    - attachments.dart
  - models/
    - envelope.dart
    - capabilities.dart
    - sse_events.dart
    - artifacts.dart
    - ide_hints.dart
    - editor_context.dart
  - utils/
    - http.dart (timeout/retry)
    - sse.dart (typed events)
    - artifacts.dart (download/head)
    - idempotency.dart

## Milestones
- M0: HTTP core + Capabilities endpoint
- M1: design-generate SSE + typed events
- M2: figma-context SSE
- M3: compat variables/symbols + ide_hints helpers
- M4: attachments (presign/ingest/result) + artifacts helpers
- M5: tests and examples

## Notes
- Auth headers: `Authorization: Bearer <ANON>`, `apikey: <ANON>`
- Respect `envelope_version`, `trace_id`, cancellation semantics, and `ready`/`aborted` events.
- Ingest result: `{ bucket, key, signedUrl }`에서 `key`는 버킷 상대 경로입니다. 직접 URL 구성 시 `bucket + '/' + key` 형태로 결합하거나, 가능하면 반환된 `signedUrl`을 그대로 사용하세요.

## Quickstart

```dart
import 'dart:async';
import 'package:cogo_chat_sdk_flutter/cogo_chat_client.dart';

final client = CogoChatClient(
  edgeBase: 'https://<ref>.functions.supabase.co/functions/v1',
  anonKey: '<ANON>',
  supabaseUrl: 'https://<ref>.supabase.co',
);

// Capabilities
final caps = await client.capabilities.info();
print(caps.envelopeVersion);

// symbols.map
final res = await client.symbolsMap.map(body: {
  'projectId': '<uuid>',
  'page_id': 1,
  'cogo_ui_json': [ { 'type': 'container' } ],
});
print(res['trace_id']);

// design-generate (SSE)
final abort = StreamController<void>();
await client.designGenerate.stream({'prompt': 'Login'}, (event, data) {
  print('event=$event data=$data');
  if (event == 'done' || event == 'error') abort.add(null);
}, abort: abort);
await abort.close();
```

## Attachments (Ingest)

```dart
// 1) presign
final pre = await client.attachments.presign(projectId: '<uuid>', fileName: 'big.json');

// 2) upload via pre['signedUrl'] (client-side)

// 3) enqueue ingest
final ins = await client.attachments.ingest(projectId: '<uuid>', storageKey: pre['key']);
final traceId = ins['trace_id'];

// 4) poll result
final res2 = await client.attachments.ingestResult(traceId: traceId);
// Note: res2['key']는 버킷 상대 경로이며, 다운로드는 res2['signedUrl'] 사용을 권장합니다.
print(res2);
```

## streamOrRealtime (Hybrid SSE → Realtime)

```dart
import 'dart:async';
import 'package:cogo_chat_sdk_flutter/cogo_chat_client.dart';

final supa = SupabaseUtils.createClient(
  supabaseUrl: 'https://<ref>.supabase.co',
  anonKey: '<ANON>',
);

final traceSub = TraceSubscriber(supa);
final abort = StreamController<void>();
await streamOrRealtime(
  url: Uri.parse('https://<ref>.functions.supabase.co/functions/v1/design-generate'),
  headers: { 'Authorization': 'Bearer <ANON>', 'apikey': '<ANON>' },
  body: { 'prompt': 'Hello', 'dev_flags': { 'dev_queue_sim': true, 'dev_handoff_after_ms': 100 } },
  onEvent: (event, json) {
    // Handle meta/delta/done/error/queued/handoff
  },
  traceSubscriber: traceSub,
  abort: abort,
);
await abort.close();
```

## Tests

Run the SDK tests locally with your Supabase environment:

```bash
export SUPABASE_PROJECT_ID=<ref>
export SUPABASE_EDGE=https://$SUPABASE_PROJECT_ID.functions.supabase.co/functions/v1
export SUPABASE_URL=https://$SUPABASE_PROJECT_ID.supabase.co
export SUPABASE_ANON_KEY=<ANON>

cd packages/cogo-chat-sdk-flutter
flutter pub get
flutter test -r expanded --concurrency=1
```

Expected: All tests pass. You will see detailed logs for SSE events and ingest polling in verbose mode.

## TS ↔ Flutter Mapping

| Category | TypeScript | Flutter |
|---|---|---|
| Realtime | `createSupabaseTraceSubscriber()` (broadcast `trace:{id}`) | `TraceSubscriber.streamBroadcast()` |
| SSE | `sse-typed.ts` `streamTyped` | `utils/sse_typed.dart` `streamTyped` |
| Hybrid | `streamOrRealtime()` | `streamOrRealtime()` |
| HTTP | `http.ts` `fetchJson` | `utils/http.dart` `fetchJson` |
| Artifacts | `artifacts.ts` `head/downloadJson` | `utils/artifacts.dart` `headStatus/downloadJson` |
| Storage | `artifacts-supabase.ts` | `utils/artifacts_supabase.dart` |
| Idempotency | `idempotency.ts` `newIdempotencyKey` | `utils/idempotency.dart` `newIdempotencyKey` |
| Editor | `editor.ts` `buildEditorContext` | `utils/editor.dart` `buildEditorContext` |
| IDE Hints | `ide-hints.ts` `selectToast` | `models/ide_hints.dart` `selectToast` |
| Endpoints | `endpoints.ts` | `cogo_chat_client.dart` + `endpoints/*` |

## Realtime (optional)

```dart
import 'package:cogo_chat_sdk_flutter/cogo_chat_client.dart';

final supa = SupabaseUtils.createClient(
  supabaseUrl: 'https://<ref>.supabase.co',
  anonKey: '<ANON>',
);

final trace = TraceStream(supa);
trace.streamBusEventsForTrace('<traceId>').listen((rows) {
  for (final r in rows) {
    // handle broadcasted bus_events rows
    print(r);
  }
});
```
