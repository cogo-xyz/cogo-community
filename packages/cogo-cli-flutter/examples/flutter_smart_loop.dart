import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cogo_cli_flutter/http_client.dart';

/// UX-first chat loop example for Flutter (desktop-friendly)
/// - Minimizes user involvement (auto-approves safe ops)
/// - Applies small edits automatically, queues large/binary for preview
/// - Skips disallowed commands safely
class SmartChatLoopController {
  final EdgeHttp http;
  final String logDir;
  final int stepTimeoutSec;
  final int maxSteps;
  final int autoApplyEditMaxBytes;
  final String includeGlob;
  final String excludeGlob;

  SmartChatLoopController({
    required this.http,
    this.logDir = '.cogo/session',
    this.stepTimeoutSec = 20,
    this.maxSteps = 5,
    this.autoApplyEditMaxBytes = 200000, // 200 KB
    this.includeGlob = '',
    this.excludeGlob = '',
  });

  /// Send a message, then iterate up to [maxSteps] using UX-friendly policy.
  Future<void> sendAndLoop({
    required String message,
    String Function()? projectIdProvider,
    String? followupMessage,
    void Function(Map summary)? onActionsSummary,
    void Function(String text)? onAgentText,
  }) async {
    final pid = (projectIdProvider?.call() ?? _projectId());
    final body = jsonEncode({'projectId': pid, 'text': message});
    final r = await http.post('/chat-gateway', body);
    final o = _tryJson(r.body) as Map;
    String tid = o['trace_id']?.toString() ?? '';
    if (tid.isEmpty && o['result'] is Map) tid = (o['result']['trace_id']?.toString() ?? '');
    if (tid.isEmpty) return;

    await Directory(logDir).create(recursive: true);
    File('$logDir/trace_id.txt').writeAsStringSync(tid);

    for (int step = 1; step <= maxSteps; step++) {
      if (!await _waitReady(tid, timeoutSec: stepTimeoutSec)) break;
      final rs = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(tid));
      final ro = _tryJson(rs.body) as Map;
      final actions = (ro['next_actions'] as List?) ?? const [];
      final agentText = ((ro['output'] as Map?)?['text']?.toString() ?? '').trim();
      if (agentText.isNotEmpty) onAgentText?.call(agentText);

      final approved = await _preApproveActions(actions);
      if (approved.isEmpty) break;
      final summary = await dispatchNextActions(
        approved,
        hitl: false, // we pre-approve, so no stdin prompts
        auto: true,
        http: http,
        traceId: tid,
        logDir: logDir,
        includeGlob: includeGlob,
        excludeGlob: excludeGlob,
      );
      onActionsSummary?.call(summary);

      // Optional follow-up to continue improving output
      final fuMsg = (followupMessage?.trim().isNotEmpty ?? false) ? followupMessage!.trim() : 'continue';
      final fuBody = jsonEncode({'projectId': pid, 'text': fuMsg});
      final r2 = await http.post('/chat-gateway', fuBody);
      final o2 = _tryJson(r2.body) as Map;
      String newTid = o2['trace_id']?.toString() ?? '';
      if (newTid.isEmpty && o2['result'] is Map) newTid = (o2['result']['trace_id']?.toString() ?? '');
      if (newTid.isEmpty) break;
      tid = newTid;
      File('$logDir/trace_id.txt').writeAsStringSync(tid);
    }
  }

  /// Policy: auto-approve safe CLI and small apply_edits; skip denied/unallowed
  Future<List<Map<String, dynamic>>> _preApproveActions(List actions) async {
    final cfg = loadRunnerConfig();
    final approved = <Map<String, dynamic>>[];
    for (final a in actions) {
      if (a is! Map) continue;
      final type = (a['type']?.toString() ?? '').toLowerCase();
      if (type == 'cli') {
        final cmd = (a['cmd']?.toString() ?? '').trim();
        if (cmd.isEmpty) continue;
        if (cfg.denylist.contains(cmd)) {
          // hard deny
          continue;
        }
        if (cfg.allowlist.isNotEmpty && !cfg.allowlist.contains(cmd)) {
          // not explicitly allowed → skip
          continue;
        }
        // auto-safe (json-set/merge/remove), or explicitly allowed
        approved.add({
          'type': 'cli',
          'cmd': cmd,
          if (a['args'] is List) 'args': a['args'],
          if ((a['cwd']?.toString() ?? '').isNotEmpty) 'cwd': a['cwd']?.toString(),
          if (a['timeout'] != null) 'timeout': a['timeout'],
          if (a['env'] is Map) 'env': a['env'],
          'hitl': false,
        });
      } else if (type == 'apply_edits') {
        final edits = (a['edits'] is List) ? (a['edits'] as List) : const [];
        final filtered = <Map<String, dynamic>>[];
        for (final e in edits) {
          if (e is! Map) continue;
          final p = (e['path']?.toString() ?? '').trim();
          final content = (e['content']?.toString() ?? '');
          if (p.isEmpty) continue;
          if (includeGlob.isNotEmpty && !p.contains(includeGlob)) continue;
          if (excludeGlob.isNotEmpty && p.contains(excludeGlob)) continue;
          if (content.length > autoApplyEditMaxBytes) continue; // leave for manual preview later
          if (_looksBinaryPath(p)) continue;
          filtered.add({'path': p, 'content': content});
        }
        if (filtered.isNotEmpty) {
          approved.add({'type': 'apply_edits', 'edits': filtered});
        }
      } else if (type == 'git_ops') {
        // out of scope → skip
        continue;
      }
    }
    return approved;
  }

  Future<bool> _waitReady(String tid, {required int timeoutSec}) async {
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

  bool _looksBinaryPath(String path) {
    final lower = path.toLowerCase();
    const binExt = [
      '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.pdf', '.zip', '.tar', '.gz', '.mp4', '.mp3', '.mov', '.exe', '.dll'
    ];
    for (final e in binExt) { if (lower.endsWith(e)) return true; }
    return false;
  }

  Object _tryJson(String s) { try { return jsonDecode(s); } catch (_) { return {'text': s}; } }
}


