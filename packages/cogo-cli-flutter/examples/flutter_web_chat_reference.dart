import 'dart:async';
import 'dart:convert';
import 'dart:html' as html; // Flutter Web target

import 'package:cogo_cli_flutter/http_client.dart';

/// Flutter Web Chat Reference
/// - runner_type=web: no local processes or file writes
/// - apply_edits: keep in-memory and offer browser download
/// - complex bundles: call a server API to run loop remotely (placeholder)
Future<void> main() async {
  final ctrl = WebChatController(
    http: EdgeHttp(EdgeHttp.buildBase(), html.window.localStorage['SUPABASE_ANON_KEY'] ?? ''),
  );

  // Multilingual: Japanese example
  await ctrl.send('モデルJSONを作成し、スキーマで検証して、差分を表示して', lang: 'ja');
}

class WebChatController {
  final EdgeHttp http;
  WebChatController({required this.http});

  Future<void> send(String message, {String? lang}) async {
    final body = jsonEncode({
      'projectId': _projectId(),
      'text': message,
      if (lang != null && lang.trim().isNotEmpty) 'lang': lang.trim(),
    });
    final r = await http.post('/chat-gateway', body);
    final o = _tryJson(r.body) as Map;
    final tid = o['trace_id']?.toString() ?? (o['result'] is Map ? (o['result']['trace_id']?.toString() ?? '') : '');
    if (tid.isEmpty) return;
    await _loopOnce(tid);
  }

  Future<void> _loopOnce(String tid) async {
    final ready = await _waitReady(tid, 20);
    if (!ready) return;
    final rs = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(tid));
    final ro = _tryJson(rs.body) as Map;
    final actions = (ro['next_actions'] as List?) ?? const [];
    final agentText = ((ro['output'] as Map?)?['text']?.toString() ?? '').trim();
    if (agentText.isNotEmpty) _showText(agentText);

    // Web policy:
    // - Skip cli/apply_edits locally
    // - If apply_edits exists, present preview+download instead
    // - For complex bundles, call remote loop API (placeholder)
    bool hasApply = false;
    for (final a in actions) {
      if (a is! Map) continue;
      final t = (a['type']?.toString() ?? '').toLowerCase();
      if (t == 'apply_edits') {
        hasApply = true;
        final edits = (a['edits'] as List?) ?? const [];
        for (final e in edits) {
          if (e is! Map) continue;
          final path = (e['path']?.toString() ?? 'artifact.txt');
          final content = (e['content']?.toString() ?? '');
          _previewDiffAndDownload(path, content);
        }
      }
    }
    if (!hasApply && actions.isNotEmpty) {
      _showText('This action requires server execution. Click to run remotely.');
      // TODO: call a server API to run loop remotely; poll a web-accessible summary
    }
  }

  Future<bool> _waitReady(String tid, int timeoutSec) async {
    final started = DateTime.now();
    while (true) {
      final rr = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(tid));
      final ro = _tryJson(rr.body) as Map;
      final st = (ro['status']?.toString() ?? '');
      if (st == 'ready' || st == 'failed') return true;
      if (DateTime.now().difference(started).inSeconds >= timeoutSec) return false;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  void _previewDiffAndDownload(String path, String content) {
    // Simple preview: show size and first lines (a real app would render a diff UI)
    _showText('[edit] $path (${content.length} bytes)');
    _download(path.split('/').last, content);
  }

  void _download(String filename, String text) {
    final bytes = utf8.encode(text);
    final blob = html.Blob([bytes], 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  void _showText(String text) {
    // Minimal rendering for reference; integrate with real Flutter widgets in app
    html.window.console.log(text);
  }

  String _projectId() {
    final pid = html.window.localStorage['COGO_PROJECT_ID'] ?? '';
    return pid.trim().isNotEmpty ? pid : '00000000-0000-4000-8000-000000000000';
  }

  Object _tryJson(String s) { try { return jsonDecode(s); } catch (_) { return {'text': s}; } }
}


