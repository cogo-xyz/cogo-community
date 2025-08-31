#!/usr/bin/env dart
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:cogo_cli_flutter/http_client.dart';
import 'package:cogo_cli_flutter/json_ops.dart';
import 'package:http/http.dart' as httpx;

void j(Object o) => stdout.writeln(const JsonEncoder.withIndent('  ').convert(o));

ArgParser build() {
  final p = ArgParser();
  // Global options
  p.addOption('project-id', help: 'Override project UUID (falls back to env)');
  p.addOption('storage-key', help: 'Storage key for attachments ingest');
  p.addOption('timeout-seconds', help: 'Global timeout in seconds for polling operations');
  p.addOption('page-id', help: 'Optional page id for compat endpoints');
  p.addOption('out-key', help: 'Write generated storage key to file');
  p.addOption('out-trace', help: 'Write generated trace id to file');
  p.addOption('out-json', help: 'Write last JSON payload to file');
  p.addCommand('info');
  p.addCommand('compat-symbols-map');
  p.addCommand('compat-variables-derive');
  p.addCommand('compat-bdd-generate');
  p.addCommand('compat-bdd-refine');
  p.addCommand('compat-actionflow-refine');
  p.addCommand('compat-generate');
  final tr = ArgParser()..addOption('trace-id', help: 'Trace ID');
  p.addCommand('trace-status', tr);
  final pres = ArgParser()..addFlag('print-key-only', negatable: false);
  p.addCommand('attachments-presign', pres);
  p.addCommand('attachments-presign-key');
  final ing = ArgParser()..addFlag('wait', negatable: false, help: 'Wait for result (poll)');
  p.addCommand('attachments-ingest', ing);
  final res = ArgParser()..addOption('trace-id', help: 'Trace ID');
  p.addCommand('attachments-result', res);
  final dl = ArgParser()
    ..addOption('trace-id', help: 'Trace ID to resolve signed URL')
    ..addOption('signed-url', help: 'Signed URL to download directly')
    ..addOption('out-file', help: 'Output file path', defaultsTo: 'artifact.json');
  p.addCommand('attachments-download', dl);
  final flow = ArgParser()
    ..addOption('file', help: 'Path to a local JSON file to upload', defaultsTo: 'sample.json')
    ..addOption('timeout', help: 'Poll timeout seconds', defaultsTo: '20');
  p.addCommand('attachments-flow', flow);
  // JSON ops
  final jset = ArgParser()
    ..addOption('file', mandatory: true)
    ..addOption('pointer', mandatory: true)
    ..addOption('value', mandatory: true)
    ..addOption('backup-dir');
  p.addCommand('json-set', jset);
  final jmerge = ArgParser()
    ..addOption('file', mandatory: true)
    ..addOption('pointer', mandatory: true)
    ..addOption('value', mandatory: true)
    ..addOption('backup-dir');
  p.addCommand('json-merge', jmerge);
  final jrm = ArgParser()
    ..addOption('file', mandatory: true)
    ..addOption('pointer', mandatory: true)
    ..addOption('backup-dir');
  p.addCommand('json-remove', jrm);
  return p;
}

Object _tryJson(String s) {
  try {
    return jsonDecode(s);
  } catch (_) {
    return {'text': s};
  }
}

String _projectId(ArgResults ar) {
  final env = Platform.environment;
  final fromArg = (ar['project-id']?.toString() ?? '').trim();
  if (fromArg.isNotEmpty) return fromArg;
  final pid = (env['COGO_PROJECT_ID'] ?? env['PROJECT_ID'] ?? '').trim();
  // Use provided UUID if present; else fallback to a fixed valid UUID for testing
  final fallback = '00000000-0000-4000-8000-000000000000';
  final v = pid.isNotEmpty ? pid : fallback;
  return v;
}

void _writeIfPath(String? path, String content) {
  final p = (path ?? '').trim();
  if (p.isEmpty) return;
  try {
    File(p).writeAsStringSync(content);
  } catch (_) {}
}

String _extractKeyFromPresign(Map obj) {
  try {
    final res = (obj['result'] as Map?);
    final k = res?['key']?.toString();
    if (k != null && k.isNotEmpty) return k;
  } catch (_) {}
  try {
    final k2 = obj['key']?.toString();
    if (k2 != null && k2.isNotEmpty) return k2;
  } catch (_) {}
  return '';
}

String _extractSignedUrlFromPresign(Map obj) {
  try {
    final res = (obj['result'] as Map?);
    final u = res?['signedUrl']?.toString();
    if (u != null && u.isNotEmpty) return u;
  } catch (_) {}
  try {
    final u2 = obj['signedUrl']?.toString();
    if (u2 != null && u2.isNotEmpty) return u2;
  } catch (_) {}
  return '';
}

Future<int> main(List<String> a) async {
  final p = build();
  ArgResults ar;
  try {
    ar = p.parse(a);
  } catch (e) {
    j({'ok': false, 'error': 'parse_error', 'message': e.toString()});
    return 2;
  }

  final env = Platform.environment;
  final anon = env['SUPABASE_ANON_KEY'] ?? '';
  final base = EdgeHttp.buildBase();
  if (base.isEmpty || anon.isEmpty) {
    j({
      'ok': false,
      'error': 'config_missing',
      'need': ['SUPABASE_EDGE or SUPABASE_PROJECT_ID', 'SUPABASE_ANON_KEY']
    });
    return 2;
  }

  final http = EdgeHttp(base, anon);
  final c = ar.command;
  if (c == null) {
    stdout.writeln('Usage: cogo_cli_flutter <info|compat-symbols-map|trace-status|attachments-*>');
    return 2;
  }

  switch (c.name) {
    case 'info':
      {
        final r = await http.get('/intent-resolve/info');
        j({
          'ok': r.statusCode == 200,
          'domain': 'sdk',
          'action': 'info',
          'status': r.statusCode,
          'result': _tryJson(r.body)
        });
        return 0;
      }
    case 'compat-symbols-map':
      {
        final pidStr = (ar['page-id']?.toString() ?? '').trim();
        final pageId = int.tryParse(pidStr);
        final bodyMap = {
          'projectId': _projectId(ar),
          if (pageId != null) 'page_id': pageId,
        };
        final body = jsonEncode(bodyMap);
        final r = await http.post('/figma-compat/uui/symbols/map', body);
        j({
          'ok': r.statusCode == 200,
          'domain': 'sdk',
          'action': 'compat-symbols-map',
          'status': r.statusCode,
          'result': _tryJson(r.body)
        });
        return 0;
      }
    case 'compat-variables-derive':
      {
        final pidStr = (ar['page-id']?.toString() ?? '').trim();
        final pageId = int.tryParse(pidStr);
        final bodyMap = {
          'projectId': _projectId(ar),
          if (pageId != null) 'page_id': pageId,
          'cogo_ui_json': []
        };
        final body = jsonEncode(bodyMap);
        final r = await http.post('/figma-compat/uui/variables/derive', body);
        j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'compat-variables-derive', 'status': r.statusCode, 'result': _tryJson(r.body)});
        return 0;
      }
    case 'compat-bdd-generate':
      {
        final pidStr = (ar['page-id']?.toString() ?? '').trim();
        final pageId = int.tryParse(pidStr);
        final bodyMap = {
          'projectId': _projectId(ar),
          if (pageId != null) 'page_id': pageId,
          'cogo_ui_json': []
        };
        final body = jsonEncode(bodyMap);
        final r = await http.post('/figma-compat/uui/bdd/generate', body);
        j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'compat-bdd-generate', 'status': r.statusCode, 'result': _tryJson(r.body)});
        return 0;
      }
    case 'compat-bdd-refine':
      {
        final pidStr = (ar['page-id']?.toString() ?? '').trim();
        final pageId = int.tryParse(pidStr);
        final bodyMap = {
          'projectId': _projectId(ar),
          if (pageId != null) 'page_id': pageId,
          'current_bdd': 'Feature: Sample'
        };
        final body = jsonEncode(bodyMap);
        final r = await http.post('/figma-compat/uui/bdd/refine', body);
        j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'compat-bdd-refine', 'status': r.statusCode, 'result': _tryJson(r.body)});
        return 0;
      }
    case 'compat-actionflow-refine':
      {
        final pidStr = (ar['page-id']?.toString() ?? '').trim();
        final pageId = int.tryParse(pidStr);
        final bodyMap = {
          'projectId': _projectId(ar),
          if (pageId != null) 'page_id': pageId,
          'current_flow': {'steps': []}
        };
        final body = jsonEncode(bodyMap);
        final r = await http.post('/figma-compat/uui/actionflow/refine', body);
        j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'compat-actionflow-refine', 'status': r.statusCode, 'result': _tryJson(r.body)});
        return 0;
      }
    case 'compat-generate':
      {
        final pidStr = (ar['page-id']?.toString() ?? '').trim();
        final pageId = int.tryParse(pidStr);
        final bodyMap = {
          'projectId': _projectId(ar),
          if (pageId != null) 'page_id': pageId,
          'prompt': 'hello button image'
        };
        final body = jsonEncode(bodyMap);
        final r = await http.post('/figma-compat/uui/generate', body);
        j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'compat-generate', 'status': r.statusCode, 'result': _tryJson(r.body)});
        return 0;
      }
    case 'trace-status':
      {
        // Support either --trace-id or positional arg
        String id = (c['trace-id']?.toString() ?? '').trim();
        if (id.isEmpty) {
          final rest = c.rest;
          if (rest.isEmpty) { j({'ok': false, 'error': 'trace_id_required'}); return 2; }
          id = rest.first;
        }
        final r = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(id));
        j({
          'ok': r.statusCode == 200,
          'domain': 'sdk',
          'action': 'trace-status',
          'status': r.statusCode,
          'result': _tryJson(r.body)
        });
        return 0;
      }
    case 'attachments-presign':
      {
        final r = await http.post(
            '/figma-compat/uui/presign',
            jsonEncode({'projectId': _projectId(ar), 'fileName': 'sample.json'}));
        final obj = _tryJson(r.body);
        // write out-json if requested
        _writeIfPath(ar['out-json']?.toString(), jsonEncode(obj));
        if (ar.command is ArgResults && (ar.command as ArgResults)['print-key-only'] == true) {
          try {
            final key = (obj as Map)['result']['key'];
            stdout.writeln(key);
            _writeIfPath(ar['out-key']?.toString(), key?.toString() ?? '');
          } catch (_) {
            stdout.writeln('');
          }
          return 0;
        }
        j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'attachments-presign', 'status': r.statusCode, 'result': obj});
        return 0;
      }
    case 'attachments-presign-key':
      {
        final r = await http.post(
            '/figma-compat/uui/presign',
            jsonEncode({'projectId': _projectId(ar), 'fileName': 'sample.json'}));
        try {
          final obj = _tryJson(r.body) as Map;
          final key = (obj['result'] as Map?)?['key']?.toString() ?? '';
          stdout.writeln(key);
          _writeIfPath(ar['out-key']?.toString(), key);
          _writeIfPath(ar['out-json']?.toString(), jsonEncode(obj));
        } catch (_) { stdout.writeln(''); }
        return 0;
      }
    case 'attachments-ingest':
      {
        final rest = c.rest;
        String key = '';
        if (rest.isNotEmpty) key = rest.first;
        if (key.trim().isEmpty) {
          final opt = (ar['storage-key']?.toString() ?? '').trim();
          if (opt.isNotEmpty) key = opt;
        }
        if (key.trim().isEmpty) { j({'ok': false, 'error': 'storage_key_required'}); return 2; }
        final r = await http.post(
            '/figma-compat/uui/ingest', jsonEncode({'projectId': _projectId(ar), 'storage_key': key}));
        final obj = _tryJson(r.body);
        try {
          final traceId = (obj as Map)['result'] is Map ? ((obj['result'] as Map)['trace_id']?.toString() ?? '') : '';
          if (traceId.isNotEmpty) _writeIfPath(ar['out-trace']?.toString(), traceId);
        } catch (_) {}
        _writeIfPath(ar['out-json']?.toString(), jsonEncode(obj));
        // If --wait, poll result until ready or timeout
        if ((c['wait'] == true)) {
          String traceId = '';
          try { traceId = (obj as Map)['result'] is Map ? ((obj['result'] as Map)['trace_id']?.toString() ?? '') : ''; } catch (_) {}
          if (traceId.isEmpty) { j({'ok': false, 'error': 'trace_id_missing_for_wait', 'result': obj}); return 2; }
          final timeout = int.tryParse((ar['timeout-seconds']?.toString() ?? '20')) ?? 20;
          final started = DateTime.now();
          Map last = {};
          while (true) {
            final rr = await http.get('/figma-compat/uui/ingest/result?traceId=' + Uri.encodeComponent(traceId));
            final ro = _tryJson(rr.body) as Map;
            last = ro;
            if ((ro['status']?.toString() ?? '') == 'ready') {
              j({'ok': true, 'domain': 'sdk', 'action': 'attachments-ingest', 'status': 200, 'result': obj, 'poll': ro});
              return 0;
            }
            if (DateTime.now().difference(started).inSeconds >= timeout) {
              j({'ok': true, 'domain': 'sdk', 'action': 'attachments-ingest', 'status': 200, 'result': obj, 'timeout': timeout, 'last': last});
              return 0;
            }
            await Future<void>.delayed(const Duration(seconds: 2));
          }
        } else {
          j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'attachments-ingest', 'status': r.statusCode, 'result': obj});
          return 0;
        }
      }
    case 'attachments-result':
      {
        // Support either --trace-id or positional arg
        String id = (c['trace-id']?.toString() ?? '').trim();
        if (id.isEmpty) {
          final rest = c.rest;
          if (rest.isEmpty) { j({'ok': false, 'error': 'trace_id_required'}); return 2; }
          id = rest.first;
        }
        final timeout = int.tryParse((ar['timeout-seconds']?.toString() ?? '0')) ?? 0;
        if (timeout > 0) {
          // Poll until ready or timeout
          final started = DateTime.now();
          Map last = {};
          while (true) {
            final rr = await http.get('/figma-compat/uui/ingest/result?traceId=' + Uri.encodeComponent(id));
            final obj = _tryJson(rr.body) as Map;
            last = obj;
            if ((obj['status']?.toString() ?? '') == 'ready') {
              _writeIfPath(ar['out-json']?.toString(), jsonEncode(obj));
              j({'ok': rr.statusCode == 200, 'domain': 'sdk', 'action': 'attachments-result', 'status': rr.statusCode, 'result': obj});
              return 0;
            }
            if (DateTime.now().difference(started).inSeconds >= timeout) {
              _writeIfPath(ar['out-json']?.toString(), jsonEncode(last));
              j({'ok': true, 'domain': 'sdk', 'action': 'attachments-result', 'status': 200, 'result': last, 'timeout': timeout});
              return 0;
            }
            await Future<void>.delayed(const Duration(seconds: 2));
          }
        } else {
          final r = await http.get('/figma-compat/uui/ingest/result?traceId=' + Uri.encodeComponent(id));
          final obj = _tryJson(r.body);
          _writeIfPath(ar['out-json']?.toString(), jsonEncode(obj));
          j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'attachments-result', 'status': r.statusCode, 'result': obj});
          return 0;
        }
      }
    case 'attachments-download':
      {
        // Resolve signedUrl from either --signed-url or --trace-id
        String signedUrl = (c['signed-url']?.toString() ?? '').trim();
        if (signedUrl.isEmpty) {
          String id = (c['trace-id']?.toString() ?? '').trim();
          if (id.isEmpty) { j({'ok': false, 'error': 'need_signed_url_or_trace_id'}); return 2; }
          final r = await http.get('/figma-compat/uui/ingest/result?traceId=' + Uri.encodeComponent(id));
          final obj = _tryJson(r.body) as Map;
          try {
            signedUrl = (obj['signedUrl']?.toString() ?? '');
            if (signedUrl.isEmpty && obj['result'] is Map) {
              signedUrl = ((obj['result'] as Map)['signedUrl']?.toString() ?? '');
            }
          } catch (_) {}
          if (signedUrl.isEmpty) { j({'ok': false, 'error': 'signed_url_missing', 'result': obj}); return 2; }
        }
        final outPath = (c['out-file']?.toString() ?? 'artifact.json').trim();
        final resp = await httpx.get(Uri.parse(signedUrl));
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          j({'ok': false, 'error': 'download_failed', 'status': resp.statusCode});
          return 2;
        }
        final f = File(outPath);
        await f.parent.create(recursive: true);
        await f.writeAsBytes(resp.bodyBytes);
        j({'ok': true, 'domain': 'sdk', 'action': 'attachments-download', 'file': outPath, 'bytes': resp.bodyBytes.length});
        return 0;
      }
    case 'json-set':
      {
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final valStr = (c['value']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { j({'ok': false, 'error': 'args_missing'}); return 2; }
        dynamic value;
        try { value = jsonDecode(valStr); } catch (_) { value = valStr; }
        final data = await JsonOps.readJsonFile(path);
        final updated = JsonOps.setAtPointer(data, ptr, value) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        j({'ok': true, 'domain': 'sdk', 'action': 'json-set', 'file': path, 'pointer': ptr});
        return 0;
      }
    case 'json-merge':
      {
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final valStr = (c['value']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { j({'ok': false, 'error': 'args_missing'}); return 2; }
        dynamic patch;
        try { patch = jsonDecode(valStr); } catch (_) { patch = valStr; }
        final data = await JsonOps.readJsonFile(path);
        final base = JsonOps.getAtPointer(data, ptr);
        final merged = JsonOps.deepMerge(base, patch);
        final updated = JsonOps.setAtPointer(data, ptr, merged) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        j({'ok': true, 'domain': 'sdk', 'action': 'json-merge', 'file': path, 'pointer': ptr});
        return 0;
      }
    case 'json-remove':
      {
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { j({'ok': false, 'error': 'args_missing'}); return 2; }
        final data = await JsonOps.readJsonFile(path);
        final updated = JsonOps.removeAtPointer(data, ptr) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        j({'ok': true, 'domain': 'sdk', 'action': 'json-remove', 'file': path, 'pointer': ptr});
        return 0;
      }

    case 'attachments-flow':
      {
        // 1) presign
        final fileName = 'sample.json';
        final timeout = int.tryParse((c['timeout']?.toString() ?? '20')) ?? 20;
        final pres = await http.post(
            '/figma-compat/uui/presign',
            jsonEncode({'projectId': _projectId(ar), 'fileName': fileName}));
        final presObj = _tryJson(pres.body) as Map;
        final key = _extractKeyFromPresign(presObj);
        if (key.isEmpty) { j({'ok': false, 'error': 'presign_failed', 'result': presObj}); return 2; }

        // optional signed url
        final signedUrl = _extractSignedUrlFromPresign(presObj);
        if (signedUrl.isNotEmpty) {
          try {
            final path = (c['file']?.toString() ?? 'sample.json').trim();
            final f = File(path);
            final exists = await f.exists();
            if (!exists) { await f.writeAsString('{"ok":true,"ts":${DateTime.now().millisecondsSinceEpoch}}\n'); }
            final bytes = await f.readAsBytes();
            await EdgeHttp.putSignedUrl(signedUrl, bytes, contentType: 'application/json');
          } catch (_) {}
        }

        // 2) ingest
        final ing = await http.post(
            '/figma-compat/uui/ingest', jsonEncode({'projectId': _projectId(ar), 'storage_key': key}));
        final ingObj = _tryJson(ing.body) as Map;
        final traceId = ingObj['result'] is Map ? (ingObj['result'] as Map)['trace_id']?.toString() ?? '' : '';
        if (traceId.isEmpty) { j({'ok': false, 'error': 'ingest_failed', 'result': ingObj}); return 2; }

        // 3) poll result
        final started = DateTime.now();
        Map last = {};
        while (true) {
          final res = await http.get('/figma-compat/uui/ingest/result?traceId=' + Uri.encodeComponent(traceId));
          final obj = _tryJson(res.body) as Map;
          last = obj;
          if ((obj['status']?.toString() ?? '') == 'ready') break;
          if (DateTime.now().difference(started).inSeconds >= timeout) break;
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        j({'ok': true, 'domain': 'sdk', 'action': 'attachments-flow', 'traceId': traceId, 'presign': presObj, 'ingest': ingObj, 'result': last});
        return 0;
      }
    default:
      stdout.writeln('Unknown command');
      return 2;
  }
}


