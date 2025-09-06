## SDK Quickstart (TS & Flutter)

### TypeScript (Node)
```ts
import { createClient } from '@supabase/supabase-js';
const url = process.env.SUPABASE_URL!;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY!;
const sb = createClient(url, key);

// chat-gateway
const gw = await fetch(`${url}/functions/v1/chat-gateway`, {
  method: 'POST',
  headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` },
  body: JSON.stringify({ payload: { projectId: process.env.COGO_PROJECT_ID, text: 'hello' } })
});
console.log(await gw.json());

// json-get (GET/HEAD with ETag)
const head = await fetch(`${url}/functions/v1/json-get?project_id=${process.env.COGO_PROJECT_ID}&path=examples/af.json`, {
  method: 'HEAD', headers: { authorization: `Bearer ${key}` }
});
const etag = head.headers.get('etag');
const get = await fetch(`${url}/functions/v1/json-get?project_id=${process.env.COGO_PROJECT_ID}&path=examples/af.json`, {
  method: 'GET', headers: { authorization: `Bearer ${key}`, ...(etag ? { 'If-None-Match': etag } : {}) }
});
console.log(get.status === 304 ? { status: 304 } : await get.json());
// artifacts-list (pagination)
const al = await fetch(`${url}/functions/v1/artifacts-list`, {
  method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` },
  body: JSON.stringify({ project_id: process.env.COGO_PROJECT_ID, prefix: 'docs/cogo-agent/examples/simple-screen/', limit: 5, offset: 0 })
});
console.log(await al.json());
// kg-upsert-schedule (dev) — enqueue by prefix/window
await fetch(`${url}/functions/v1/kg-upsert-schedule`, { method:'POST', headers: { 'content-type':'application/json', authorization: `Bearer ${key}` }, body: JSON.stringify({ project_id: process.env.COGO_PROJECT_ID, prefix: 'docs/cogo-agent/examples/', window_minutes: 5, limit: 10 }) });
// figma-compat presign
await fetch(`${url}/functions/v1/figma-compat/uui/presign`, { method:'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` }, body: JSON.stringify({ projectId: process.env.COGO_PROJECT_ID, fileName: 'ui.json' }) });
// rag search
await fetch(`${url}/functions/v1/rag`, { method:'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` }, body: JSON.stringify({ q: 'hello', limit: 3 }) });
```

### Flutter (Dart)
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

final url = const String.fromEnvironment('SUPABASE_URL');
final key = const String.fromEnvironment('SUPABASE_KEY');
final project = const String.fromEnvironment('COGO_PROJECT_ID');

Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
  final resp = await http.post(
    Uri.parse('${url.replaceAll(RegExp(r'/+\$'), '')}/functions/v1/$path'),
    headers: {'authorization': 'Bearer $key','apikey': key,'content-type':'application/json'},
    body: jsonEncode(body),
  );
  return jsonDecode(resp.body) as Map<String, dynamic>;
}

void main() async {
  final gw = await post('chat-gateway', { 'payload': { 'projectId': project, 'text': 'hello' }});
  print(gw);
  // json-get HEAD → ETag
  final head = await http.head(Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/json-get?project_id=$project&path=examples/af.json'), headers: {
    'authorization': 'Bearer $key'
  });
  final etag = head.headers['etag'];
  // json-get GET with If-None-Match
  final getResp = await http.get(Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/json-get?project_id=$project&path=examples/af.json'), headers: {
    'authorization': 'Bearer $key',
    if (etag != null) 'if-none-match': etag,
  });
  if (getResp.statusCode == 304) {
    print({'status': 304});
  } else {
    print(jsonDecode(getResp.body));
  }

  // kg-upsert-schedule (POST)
  final kg = await http.post(
    Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/kg-upsert-schedule'),
    headers: {'authorization': 'Bearer $key', 'content-type': 'application/json'},
    body: jsonEncode({'project_id': project, 'prefix': 'docs/cogo-agent/examples/', 'window_minutes': 5, 'limit': 10}),
  );
  print(kg.body);
}
```

### Symbols and System Namespaces

- User-defined symbols: must start with `#` (e.g., `#cart`, `#Login`).
- System-scoped variables/namespaces: must start with `#_`.
- Allowed system roots:
  - `#_uiState`: UI state variables
  - `#_appData`: application-scoped data
  - `#_params`: flow/action parameters
- Bound variables in symbol definitions must use `#_` (example: `#_uiState.inputText`).
- Runtime scratchpads such as `#_results`, `#_currentResult` are reserved by the engine; avoid persisting them in artifacts.
