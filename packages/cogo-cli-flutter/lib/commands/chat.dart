import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:cogo_cli_flutter/http_client.dart';
import 'package:cogo_cli_flutter/core/utils.dart' as core;

void _j(Object o) => stdout.writeln(const JsonEncoder.withIndent('  ').convert(o));

String _projectId(ArgResults root) {
  final env = Platform.environment;
  final fromArg = (root['project-id']?.toString() ?? '').trim();
  if (fromArg.isNotEmpty) return fromArg;
  final pid = (env['COGO_PROJECT_ID'] ?? env['PROJECT_ID'] ?? '').trim();
  return pid.isNotEmpty ? pid : '00000000-0000-4000-8000-000000000000';
}

Future<int> handleChatSend(EdgeHttp http, ArgResults root, ArgResults c) async {
  final bodyFile = (c['body-file']?.toString() ?? '').trim();
  Map<String, dynamic> bodyMap;
  if (bodyFile.isNotEmpty) {
    try {
      final txt = File(bodyFile).readAsStringSync();
      bodyMap = core.tryJson(txt) as Map<String, dynamic>;
    } catch (e) {
      _j({'ok': false, 'error': 'body_file_read_error', 'message': e.toString()});
      return 2;
    }
  } else {
    final msg = (c['message']?.toString() ?? '').trim();
    if (msg.isEmpty) { _j({'ok': false, 'error': 'message_or_body_required'}); return 2; }
    bodyMap = {
      'projectId': _projectId(root),
      if ((c['agent-id']?.toString() ?? '').trim().isNotEmpty) 'agentId': c['agent-id']?.toString().trim(),
      if ((c['task-type']?.toString() ?? '').trim().isNotEmpty) 'task_type': c['task-type']?.toString().trim(),
      if ((c['intent']?.toString() ?? '').trim().isNotEmpty) 'intent': c['intent']?.toString().trim(),
      if ((c['lang']?.toString() ?? '').trim().isNotEmpty) 'lang': c['lang']?.toString().trim(),
      'text': msg,
    };
  }
  final r = await http.post('/chat-gateway', jsonEncode(bodyMap));
  final obj = core.tryJson(r.body);
  core.writeIfPath(root['out-json']?.toString(), jsonEncode(obj));
  try {
    final m = (obj as Map);
    String tid = m['trace_id']?.toString() ?? '';
    if (tid.isEmpty && m['result'] is Map) {
      final res = (m['result'] as Map);
      tid = res['trace_id']?.toString() ?? '';
    }
    if (tid.isNotEmpty) { core.writeIfPath(root['out-trace']?.toString(), tid); }
  } catch (_) {}
  if (c['wait'] == true) {
    String traceId = '';
    try {
      final m = (obj as Map);
      traceId = m['trace_id']?.toString() ?? '';
      if (traceId.isEmpty && m['result'] is Map) {
        final res = (m['result'] as Map);
        traceId = res['trace_id']?.toString() ?? '';
      }
    } catch (_) {}
    core.writeIfPath(root['out-trace']?.toString(), traceId);
    if (traceId.isEmpty) { _j({'ok': false, 'error': 'trace_id_missing_for_wait', 'result': obj}); return 2; }
    final cfg = loadRunnerConfig();
    final timeout = int.tryParse((root['timeout-seconds']?.toString() ?? (cfg.defaultTimeoutSec.toString()))) ?? cfg.defaultTimeoutSec;
    final started = DateTime.now();
    Map last = {};
    while (true) {
      final rr = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(traceId));
      final ro = core.tryJson(rr.body) as Map;
      last = ro;
      if ((ro['status']?.toString() ?? '') == 'ready') {
        _j({'ok': true, 'domain': 'sdk', 'action': 'chat-send', 'status': 200, 'result': obj, 'poll': ro});
        return 0;
      }
      if (DateTime.now().difference(started).inSeconds >= timeout) {
        _j({'ok': true, 'domain': 'sdk', 'action': 'chat-send', 'status': 200, 'result': obj, 'timeout': timeout, 'last': last});
        return 0;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  } else {
    _j({'ok': r.statusCode == 200, 'domain': 'sdk', 'action': 'chat-send', 'status': r.statusCode, 'result': obj});
    return 0;
  }
}

Future<int> handleChatResult(EdgeHttp http, ArgResults c) async {
  String id = (c['trace-id']?.toString() ?? '').trim();
  if (id.isEmpty) {
    final rest = c.rest;
    if (rest.isEmpty) { _j({'ok': false, 'error': 'trace_id_required'}); return 2; }
    id = rest.first;
  }
  final timeout = int.tryParse((c['timeout-seconds']?.toString() ?? '0')) ?? 0;
  if (timeout > 0) {
    final started = DateTime.now();
    Map last = {};
    while (true) {
      final rr = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(id));
      final ro = core.tryJson(rr.body) as Map;
      last = ro;
      if ((ro['status']?.toString() ?? '') == 'ready') { _j({'ok': true, 'result': ro}); return 0; }
      if (DateTime.now().difference(started).inSeconds >= timeout) { _j({'ok': true, 'timeout': timeout, 'last': last}); return 0; }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  } else {
    final r = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(id));
    _j({'ok': r.statusCode == 200, 'result': core.tryJson(r.body)});
    return 0;
  }
}


