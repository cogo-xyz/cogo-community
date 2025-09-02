import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cogo_cli_flutter/http_client.dart';

/// Chatting App Reference (All-in-one UX)
/// - In-app loop with HITL
/// - Auto-approve safe ops
/// - Mapping to CLI chat-loop for specific bundles
/// - Fallback: create/apply/validate/diff when agent returns no actions
Future<void> main() async {
  final app = ChatUXController(
    http: EdgeHttp(EdgeHttp.buildBase(), Platform.environment['SUPABASE_ANON_KEY'] ?? ''),
    logDir: '.cogo/session',
  );

  // Example user intent (Multilingual: Korean)
  await app.sendUserMessage('모델 JSON을 생성하고, 스키마로 검증한 뒤 변경점을 보여줘', lang: 'ko');

  // Optional: follow-up (minimize user involvement)
  await app.followUp('계속해줘', lang: 'ko');

  stdout.writeln('All done. Logs under ${app.logDir}');
}

class ChatUXController {
  final EdgeHttp http;
  final String logDir;
  String? currentTraceId;

  ChatUXController({required this.http, required this.logDir});

  Future<void> sendUserMessage(String text, {String? lang}) async {
    final body = jsonEncode({
      'projectId': _projectId(),
      'text': text,
      if (lang != null && lang.trim().isNotEmpty) 'lang': lang.trim(),
    });
    final r = await http.post('/chat-gateway', body);
    final o = _tryJson(r.body) as Map;
    currentTraceId = o['trace_id']?.toString() ?? (o['result'] is Map ? (o['result']['trace_id']?.toString() ?? '') : '');
    if ((currentTraceId ?? '').isEmpty) { stderr.writeln('No trace_id'); return; }
    await Directory(logDir).create(recursive: true);
    File('$logDir/trace_id.txt').writeAsStringSync(currentTraceId!);
    await _loopStep();
  }

  Future<void> followUp(String text, {String? lang}) async {
    if ((currentTraceId ?? '').isEmpty) return;
    final fu = jsonEncode({
      'projectId': _projectId(),
      'text': text,
      if (lang != null && lang.trim().isNotEmpty) 'lang': lang.trim(),
    });
    final r2 = await http.post('/chat-gateway', fu);
    final o2 = _tryJson(r2.body) as Map;
    final newTid = o2['trace_id']?.toString() ?? (o2['result'] is Map ? (o2['result']['trace_id']?.toString() ?? '') : '');
    if (newTid.isEmpty) return;
    currentTraceId = newTid;
    File('$logDir/trace_id.txt').writeAsStringSync(currentTraceId!);
    await _loopStep();
  }

  Future<void> _loopStep() async {
    final tid = currentTraceId!;
    if (!await _waitReady(tid, 20)) return;
    final rs = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(tid));
    final ro = _tryJson(rs.body) as Map;
    final actions = (ro['next_actions'] as List?) ?? const [];
    final agentText = ((ro['output'] as Map?)?['text']?.toString() ?? '').trim();
    if (agentText.isNotEmpty) stdout.writeln('[agent] $agentText');

    // 1) If mapping matches a batch JSON pipeline, delegate to CLI chat-loop
    if (_containsBatchJsonPipeline(actions)) {
      stdout.writeln('→ Delegating batch pipeline to CLI chat-loop');
      final pr = await Process.run('dart', [
        'run', 'packages/cogo-cli-flutter/bin/cogo_cli_flutter.dart',
        'chat-loop', '--resume', tid, '--auto', '--max-steps', '2',
        '--log-dir', logDir, '--out-actions', '$logDir/actions.json', '--out-summary', '$logDir/loop.json'
      ]);
      stdout.writeln(pr.stdout);
      stderr.writeln(pr.stderr);
      return;
    }

    // 2) Otherwise execute in-app via dispatcher
    if (actions.isNotEmpty) {
      final summary = await dispatchNextActions(
        actions,
        hitl: true,  // HITL in-app: ask before risky ops
        auto: false,
        http: http,
        traceId: tid,
        logDir: logDir,
        includeGlob: 'packages/',
        excludeGlob: 'build/',
      );
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(summary));
      return;
    }

    // 3) Fallback demo when agent returns no actions: create JSON → validate → diff
    stdout.writeln('→ No next_actions; running local fallback demo');
    final modelPath = 'packages/cogo-cli-flutter/examples/out/model.json';
    final model = {
      'title': 'Report',
      'version': 2,
      'items': [ {'id': 1, 'name': 'alpha'} ]
    };
    final edits = [
      { 'path': modelPath, 'content': const JsonEncoder.withIndent('  ').convert(model) }
    ];
    await dispatchNextActions([
      { 'type': 'apply_edits', 'edits': edits }
    ], hitl: false, auto: true, http: http, traceId: tid, logDir: logDir);

    // Simple validation
    final parsed = jsonDecode(await File(modelPath).readAsString()) as Map;
    final errors = <String>[];
    if (parsed['title'] is! String || (parsed['title'] as String).trim().isEmpty) errors.add('title must be non-empty string');
    if (parsed['version'] is! int || (parsed['version'] as int) < 1) errors.add('version must be >= 1');
    stdout.writeln({'validate_ok': errors.isEmpty, if (errors.isNotEmpty) 'errors': errors});

    // Diff via CLI
    final pr = await Process.run('dart', [
      'run', 'packages/cogo-cli-flutter/bin/cogo_cli_flutter.dart', 'files-changed', '--json'
    ]);
    stdout.writeln(pr.stdout);
    stderr.writeln(pr.stderr);
  }

  bool _containsBatchJsonPipeline(List actions) {
    bool hasApply = false, hasValidate = false, hasDiff = false;
    for (final a in actions) {
      if (a is! Map) continue;
      final t = (a['type']?.toString() ?? '').toLowerCase();
      if (t == 'apply_edits') hasApply = true;
      if (t == 'cli' && (a['cmd']?.toString() ?? '').toLowerCase() == 'jsonschema') hasValidate = true;
      if (t == 'cli' && (a['args'] is List) && (a['args'] as List).join(' ').contains('files-changed')) hasDiff = true;
    }
    return hasApply && hasValidate && hasDiff;
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

  String _projectId() {
    final env = Platform.environment;
    final pid = (env['COGO_PROJECT_ID'] ?? env['PROJECT_ID'] ?? '').trim();
    return pid.isNotEmpty ? pid : '00000000-0000-4000-8000-000000000000';
  }

  Object _tryJson(String s) { try { return jsonDecode(s); } catch (_) { return {'text': s}; } }
}


