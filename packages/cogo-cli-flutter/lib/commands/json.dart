import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:cogo_cli_flutter/json_ops.dart';
import 'package:cogo_cli_flutter/http_client.dart';
import 'package:http/http.dart' as http;

dynamic _safeGet(ArgResults c, String key) {
  try { return c[key]; } catch (_) { return null; }
}

bool _remoteEnabled(ArgResults c) {
  final v = (Platform.environment['COGO_JSON_REMOTE'] ?? '').toLowerCase();
  if (v == '1' || v == 'true' || v == 'yes') return true;
  final r = _safeGet(c, 'remote');
  if (r is bool && r) return true;
  return false;
}

void _writeIfPath(String? path, String content) {
  final p = (path ?? '').trim();
  if (p.isEmpty) return;
  try { File(p).writeAsStringSync(content); } catch (_) {}
}

Future<int> handleJson(ArgResults c, {String? outTrace}) async {
  switch (c.name) {
    case 'json-set':
      {
        if (_remoteEnabled(c)) {
          final base = EdgeHttp.buildBase();
          final anon = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
          if (base.isEmpty || anon.isEmpty) { return _emit({'ok': false, 'error': 'supabase_env_missing'}); }
          final edge = EdgeHttp(base, anon);
          final projectId = (_safeGet(c, 'project-id')?.toString() ?? Platform.environment['COGO_PROJECT_ID'] ?? '').trim();
          final docPath = (_safeGet(c, 'doc-path')?.toString() ?? Platform.environment['COGO_DOC_PATH'] ?? '').trim();
          final valStr = (_safeGet(c, 'value')?.toString() ?? '').trim();
          if (projectId.isEmpty || docPath.isEmpty || valStr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing_remote'}); }
          dynamic value; try { value = jsonDecode(valStr); } catch (_) { value = valStr; }
          final body = jsonEncode({ 'project_id': projectId, 'path': docPath, 'value': value });
          final retries = int.tryParse((_safeGet(c, 'retry')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultRetries;
          final backoff = int.tryParse((_safeGet(c, 'retry-backoff-ms')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultBackoffMs;
          final timeoutSec = int.tryParse((_safeGet(c, 'timeout-seconds')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultTimeoutSec;
          final headers = <String, String>{};
          final idem = (_safeGet(c, 'idempotency-key')?.toString() ?? '').trim();
          if (idem.isNotEmpty) headers['Idempotency-Key'] = idem;
          int attempt = 0; http.Response resp = http.Response('', 500);
          while (true) {
            attempt++;
            try {
              resp = await edge.postWithHeaders('/json-set', body, headers: headers, timeout: (timeoutSec>0)? Duration(seconds: timeoutSec): null);
            } catch (_) { resp = http.Response('', 500); }
            if (resp.statusCode >= 200 && resp.statusCode < 300) break;
            if (attempt > retries) break;
            await Future<void>.delayed(Duration(milliseconds: backoff * attempt));
          }
          final obj = (resp.body.isEmpty? {} : jsonDecode(resp.body));
          try { final tid = (obj is Map) ? (obj['trace_id']?.toString() ?? '') : ''; if (tid.isNotEmpty) _writeIfPath(outTrace, tid); } catch (_) {}
          return _emit({ 'ok': resp.statusCode == 200, 'status': resp.statusCode, 'response': obj });
        }
        final path = ((c['file']?.toString() ?? '').trim());
        final ptr = ((c['pointer']?.toString() ?? '').trim());
        final valStr = ((c['value']?.toString() ?? '').trim());
        final backup = ((c['backup-dir']?.toString() ?? '').trim());
        if (path.isEmpty || ptr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing'}); }
        dynamic value; try { value = jsonDecode(valStr); } catch (_) { value = valStr; }
        final data = await JsonOps.readJsonFile(path);
        final updated = JsonOps.setAtPointer(data, ptr, value) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        return _emit({'ok': true, 'domain': 'sdk', 'action': 'json-set', 'file': path, 'pointer': ptr});
      }
    case 'json-merge':
      {
        if (_remoteEnabled(c)) {
          final base = EdgeHttp.buildBase();
          final anon = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
          if (base.isEmpty || anon.isEmpty) { return _emit({'ok': false, 'error': 'supabase_env_missing'}); }
          final edge = EdgeHttp(base, anon);
          final projectId = (_safeGet(c, 'project-id')?.toString() ?? Platform.environment['COGO_PROJECT_ID'] ?? '').trim();
          final docPath = (_safeGet(c, 'doc-path')?.toString() ?? Platform.environment['COGO_DOC_PATH'] ?? '').trim();
          final valStr = (_safeGet(c, 'value')?.toString() ?? '').trim();
          final mode = (_safeGet(c, 'merge')?.toString() ?? 'deep').trim().toLowerCase();
          if (projectId.isEmpty || docPath.isEmpty || valStr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing_remote'}); }
          dynamic patch; try { patch = jsonDecode(valStr); } catch (_) { patch = valStr; }
          final body = jsonEncode({ 'project_id': projectId, 'path': docPath, 'patch': patch, 'merge': (mode == 'shallow') ? 'shallow' : 'deep' });
          final retries = int.tryParse((_safeGet(c, 'retry')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultRetries;
          final backoff = int.tryParse((_safeGet(c, 'retry-backoff-ms')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultBackoffMs;
          final timeoutSec = int.tryParse((_safeGet(c, 'timeout-seconds')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultTimeoutSec;
          int attempt = 0; http.Response resp = http.Response('', 500);
          while (true) {
            attempt++;
            try {
              resp = await edge.postWithHeaders('/json-merge', body, timeout: (timeoutSec>0)? Duration(seconds: timeoutSec): null);
            } catch (_) { resp = http.Response('', 500); }
            if (resp.statusCode >= 200 && resp.statusCode < 300) break;
            if (attempt > retries) break;
            final is429 = (resp.statusCode == 429);
            final delayMs = (backoff * attempt) * (is429 ? 2 : 1);
            await Future<void>.delayed(Duration(milliseconds: delayMs));
          }
          final obj = (resp.body.isEmpty? {} : jsonDecode(resp.body));
          try { final tid = (obj is Map) ? (obj['trace_id']?.toString() ?? '') : ''; if (tid.isNotEmpty) _writeIfPath(outTrace, tid); } catch (_) {}
          return _emit({ 'ok': resp.statusCode == 200, 'status': resp.statusCode, 'response': obj });
        }
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final valStr = (c['value']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing'}); }
        dynamic patch; try { patch = jsonDecode(valStr); } catch (_) { patch = valStr; }
        final data = await JsonOps.readJsonFile(path);
        final base = JsonOps.getAtPointer(data, ptr);
        final merged = JsonOps.deepMerge(base, patch);
        final updated = JsonOps.setAtPointer(data, ptr, merged) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        return _emit({'ok': true, 'domain': 'sdk', 'action': 'json-merge', 'file': path, 'pointer': ptr});
      }
    case 'json-remove':
      {
        if (_remoteEnabled(c)) {
          final base = EdgeHttp.buildBase();
          final anon = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
          if (base.isEmpty || anon.isEmpty) { return _emit({'ok': false, 'error': 'supabase_env_missing'}); }
          final edge = EdgeHttp(base, anon);
          final projectId = (_safeGet(c, 'project-id')?.toString() ?? Platform.environment['COGO_PROJECT_ID'] ?? '').trim();
          final docPath = (_safeGet(c, 'doc-path')?.toString() ?? Platform.environment['COGO_DOC_PATH'] ?? '').trim();
          final plist = (_safeGet(c, 'pointers')?.toString() ?? '').trim();
          if (projectId.isEmpty || docPath.isEmpty || plist.isEmpty) { return _emit({'ok': false, 'error': 'args_missing_remote'}); }
          final pointers = plist.split(',').map((e)=> e.trim()).where((e)=> e.isNotEmpty).toList();
          final body = jsonEncode({ 'project_id': projectId, 'path': docPath, 'pointers': pointers });
          final retries = int.tryParse((_safeGet(c, 'retry')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultRetries;
          final backoff = int.tryParse((_safeGet(c, 'retry-backoff-ms')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultBackoffMs;
          final timeoutSec = int.tryParse((_safeGet(c, 'timeout-seconds')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultTimeoutSec;
          int attempt = 0; http.Response resp = http.Response('', 500);
          while (true) {
            attempt++;
            try {
              resp = await edge.postWithHeaders('/json-remove', body, timeout: (timeoutSec>0)? Duration(seconds: timeoutSec): null);
            } catch (_) { resp = http.Response('', 500); }
            if (resp.statusCode >= 200 && resp.statusCode < 300) break;
            if (attempt > retries) break;
            final is429 = (resp.statusCode == 429);
            final delayMs = (backoff * attempt) * (is429 ? 2 : 1);
            await Future<void>.delayed(Duration(milliseconds: delayMs));
          }
          final obj = (resp.body.isEmpty? {} : jsonDecode(resp.body));
          try { final tid = (obj is Map) ? (obj['trace_id']?.toString() ?? '') : ''; if (tid.isNotEmpty) _writeIfPath(outTrace, tid); } catch (_) {}
          return _emit({ 'ok': resp.statusCode == 200, 'status': resp.statusCode, 'response': obj });
        }
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing'}); }
        final data = await JsonOps.readJsonFile(path);
        final updated = JsonOps.removeAtPointer(data, ptr) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        return _emit({'ok': true, 'domain': 'sdk', 'action': 'json-remove', 'file': path, 'pointer': ptr});
      }
    case 'json-get':
      {
        if (!_remoteEnabled(c)) { return _emit({'ok': false, 'error': 'remote_only'}); }
        final base = EdgeHttp.buildBase();
        final anon = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
        if (base.isEmpty || anon.isEmpty) { return _emit({'ok': false, 'error': 'supabase_env_missing'}); }
        final edge = EdgeHttp(base, anon);
        final projectId = (_safeGet(c, 'project-id')?.toString() ?? Platform.environment['COGO_PROJECT_ID'] ?? '').trim();
        final docPath = (_safeGet(c, 'doc-path')?.toString() ?? Platform.environment['COGO_DOC_PATH'] ?? '').trim();
        if (projectId.isEmpty || docPath.isEmpty) { return _emit({'ok': false, 'error': 'args_missing_remote'}); }
        final timeoutSec = int.tryParse((_safeGet(c, 'timeout-seconds')?.toString() ?? '').trim()) ?? loadRunnerConfig().defaultTimeoutSec;
        final r = (timeoutSec>0)
          ? await edge.postWithHeaders('/json-get', jsonEncode({'project_id': projectId, 'path': docPath}), timeout: Duration(seconds: timeoutSec))
          : await edge.post('/json-get', jsonEncode({'project_id': projectId, 'path': docPath}));
        return _emit({'ok': r.statusCode == 200, 'status': r.statusCode, 'response': (r.body.isEmpty? {} : jsonDecode(r.body))});
      }
    case 'json-list':
      {
        if (!_remoteEnabled(c)) { return _emit({'ok': false, 'error': 'remote_only'}); }
        final base = EdgeHttp.buildBase();
        final anon = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
        if (base.isEmpty || anon.isEmpty) { return _emit({'ok': false, 'error': 'supabase_env_missing'}); }
        final edge = EdgeHttp(base, anon);
        final projectId = (_safeGet(c, 'project-id')?.toString() ?? Platform.environment['COGO_PROJECT_ID'] ?? '').trim();
        final prefix = (_safeGet(c, 'prefix')?.toString() ?? '').trim();
        final limit = int.tryParse((_safeGet(c, 'limit')?.toString() ?? '').trim()) ?? 100;
        if (projectId.isEmpty) { return _emit({'ok': false, 'error': 'args_missing_remote'}); }
        final body = {'project_id': projectId, if (prefix.isNotEmpty) 'prefix': prefix, 'limit': limit};
        final r = await edge.post('/json-list', jsonEncode(body));
        return _emit({'ok': r.statusCode == 200, 'status': r.statusCode, 'response': (r.body.isEmpty? {} : jsonDecode(r.body))});
      }
  }
  return _emit({'ok': false, 'error': 'unknown_json_command'});
}

int _emit(Map obj) { print(const JsonEncoder.withIndent('  ').convert(obj)); return (obj['ok'] == true) ? 0 : 2; }


