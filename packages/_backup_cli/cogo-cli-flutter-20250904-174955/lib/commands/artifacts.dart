import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as httpx;
import 'package:cogo_cli_flutter/http_client.dart';
import 'package:cogo_cli_flutter/core/utils.dart' as core;

void _j(Object o) => stdout.writeln(const JsonEncoder.withIndent('  ').convert(o));

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

Future<int> handleArtifacts(EdgeHttp http, ArgResults c, String projectId, ArgResults root) async {
  switch (c.name) {
    case 'artifacts-upload':
      {
        final path = (c['file']?.toString() ?? '').trim();
        if (path.isEmpty) { _j({'ok': false, 'error': 'file_required'}); return 2; }
        final pres = await http.post('/figma-compat/uui/presign', jsonEncode({'projectId': projectId, 'fileName': path.split('/').last}));
        final obj = core.tryJson(pres.body) as Map;
        final key = _extractKeyFromPresign(obj);
        final signedUrl = _extractSignedUrlFromPresign(obj);
        if (signedUrl.isEmpty) { _j({'ok': false, 'error': 'presign_failed', 'result': obj}); return 2; }
        final bytes = await File(path).readAsBytes();
        final put = await EdgeHttp.putSignedUrl(signedUrl, bytes, contentType: core.contentTypeFor(path));
        final ok = put.statusCode >= 200 && put.statusCode < 300;
        core.writeIfPath(root['out-key']?.toString(), key);
        _j({'ok': ok, 'domain': 'sdk', 'action': 'artifacts-upload', 'status': put.statusCode, 'key': key});
        return ok ? 0 : 2;
      }
    case 'artifacts-upload-batch':
      {
        final files = c.rest;
        if (files.isEmpty) { _j({'ok': false, 'error': 'files_required'}); return 2; }
        final cfg = loadRunnerConfig();
        final maxRetries = int.tryParse((c['retry']?.toString() ?? (cfg.defaultRetries.toString()))) ?? cfg.defaultRetries;
        final backoffMs = int.tryParse((c['retry-backoff-ms']?.toString() ?? (cfg.defaultBackoffMs.toString()))) ?? cfg.defaultBackoffMs;
        final conc = (int.tryParse((c['concurrency']?.toString() ?? '2')) ?? 2).clamp(1, 8);
        final results = <Map<String, dynamic>>[];
        final queue = List<String>.from(files.map((e)=> e.toString()));
        final futures = <Future>[];
        Future<void> worker() async {
          while (true) {
            if (queue.isEmpty) break;
            final path = queue.removeAt(0);
            int attempt = 0;
            while (true) {
              attempt++;
              try {
                final pres = await http.post('/figma-compat/uui/presign', jsonEncode({'projectId': projectId, 'fileName': path.split('/').last}));
                final obj = core.tryJson(pres.body) as Map;
                final key = _extractKeyFromPresign(obj);
                final signedUrl = _extractSignedUrlFromPresign(obj);
                if (signedUrl.isEmpty) { throw Exception('presign_failed'); }
                final bytes = await File(path).readAsBytes();
                final put = await EdgeHttp.putSignedUrl(signedUrl, bytes, contentType: core.contentTypeFor(path));
                final ok = put.statusCode >= 200 && put.statusCode < 300;
                results.add({'file': path, 'ok': ok, 'status': put.statusCode, 'key': key, 'attempts': attempt});
                break;
              } catch (e) {
                if (attempt > maxRetries) {
                  results.add({'file': path, 'ok': false, 'error': e.toString(), 'attempts': attempt});
                  break;
                }
                await Future<void>.delayed(Duration(milliseconds: backoffMs * attempt));
              }
            }
          }
        }
        for (int i = 0; i < conc; i++) { futures.add(worker()); }
        await Future.wait(futures);
        _j({'ok': true, 'domain': 'sdk', 'action': 'artifacts-upload-batch', 'results': results});
        return 0;
      }
    case 'artifacts-download':
      {
        String signedUrl = (c['signed-url']?.toString() ?? '').trim();
        if (signedUrl.isEmpty) {
          String id = (c['trace-id']?.toString() ?? '').trim();
          if (id.isEmpty) { _j({'ok': false, 'error': 'need_signed_url_or_trace_id'}); return 2; }
          final r = await http.get('/figma-compat/uui/ingest/result?traceId=' + Uri.encodeComponent(id));
          final obj = core.tryJson(r.body) as Map;
          try {
            signedUrl = (obj['signedUrl']?.toString() ?? '');
            if (signedUrl.isEmpty && obj['result'] is Map) {
              signedUrl = ((obj['result'] as Map)['signedUrl']?.toString() ?? '');
            }
          } catch (_) {}
          if (signedUrl.isEmpty) { _j({'ok': false, 'error': 'signed_url_missing', 'result': obj}); return 2; }
        }
        final outPath = (c['out-file']?.toString() ?? 'artifact.json').trim();
        final resp = await httpx.get(Uri.parse(signedUrl));
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          _j({'ok': false, 'error': 'download_failed', 'status': resp.statusCode});
          return 2;
        }
        final f = File(outPath);
        await f.parent.create(recursive: true);
        await f.writeAsBytes(resp.bodyBytes);
        _j({'ok': true, 'domain': 'sdk', 'action': 'artifacts-download', 'file': outPath, 'bytes': resp.bodyBytes.length});
        return 0;
      }
  }
  return 2;
}


