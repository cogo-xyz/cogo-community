import 'dart:convert';
import 'dart:io';

import 'package:cogo_cli_flutter/http_client.dart';

/// Hybrid loop example:
/// - Flutter drives the conversation (HITL approvals in-app)
/// - For specific mappings (batch JSON pipeline), delegate to CLI chat-loop
/// - Otherwise, execute next_actions directly via dispatcher
Future<void> main() async {
  final base = EdgeHttp.buildBase();
  final anon = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  final http = EdgeHttp(base, anon);

  // 1) User message (simulated)
  final body = jsonEncode({'projectId': _projectId(), 'text': 'Create JSON, validate, show diff'});
  final r = await http.post('/chat-gateway', body);
  final o = _tryJson(r.body) as Map;
  String tid = o['trace_id']?.toString() ?? '';
  if (tid.isEmpty && o['result'] is Map) tid = (o['result']['trace_id']?.toString() ?? '');
  if (tid.isEmpty) { stderr.writeln('No trace_id'); exit(2); }

  // 2) Wait until ready and fetch next_actions
  if (!await _waitReady(http, tid, 20)) { stderr.writeln('Timeout'); exit(2); }
  final rs = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(tid));
  final ro = _tryJson(rs.body) as Map;
  final actions = (ro['next_actions'] as List?) ?? const [];

  // 3) Mapping: if actions contain a batch JSON pipeline, delegate to CLI loop
  if (_containsBatchJsonPipeline(actions)) {
    stdout.writeln('Delegating to CLI loop for batch pipeline...');
    final cliArgs = [
      'run', 'packages/cogo-cli-flutter/bin/cogo_cli_flutter.dart',
      'chat-loop', '--resume', tid,
      '--auto', '--max-steps', '2',
      '--log-dir', '.cogo/session',
      '--out-actions', '.cogo/actions.json',
      '--out-summary', '.cogo/loop-summary.json'
    ];
    final pr = await Process.run('dart', cliArgs);
    stdout.writeln(pr.stdout);
    stderr.writeln(pr.stderr);
    exit(pr.exitCode);
  }

  // 4) Otherwise: execute locally via dispatcher
  final summary = await dispatchNextActions(
    actions,
    hitl: true,  // in-app HITL (would be wired to Flutter UI)
    auto: false,
    http: http,
    traceId: tid,
    logDir: '.cogo/session',
    includeGlob: 'packages/',
    excludeGlob: 'build/',
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(summary));
}

bool _containsBatchJsonPipeline(List actions) {
  // Heuristic: look for apply_edits -> cli(jsonschema) -> cli(files-changed)
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

Future<bool> _waitReady(EdgeHttp http, String tid, int timeoutSec) async {
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


