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

// json-get
const get = await fetch(`${url}/functions/v1/json-get`, {
  method: 'POST',
  headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` },
  body: JSON.stringify({ project_id: process.env.COGO_PROJECT_ID, path: 'examples/af.json' })
});
console.log(await get.json());
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
  final get = await post('json-get', { 'project_id': project, 'path': 'examples/af.json' });
  print(get);
}
```
