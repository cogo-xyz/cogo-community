import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:cogo_cli_flutter/core/utils.dart' as core;

void _j(Object o) => stdout.writeln(const JsonEncoder.withIndent('  ').convert(o));

Future<int> handleConfigValidate() async {
  try {
    final f = File('.cogo/runner.config.json');
    if (!f.existsSync()) { _j({'ok': false, 'error': 'config_missing', 'file': f.path}); return 2; }
    final txt = f.readAsStringSync();
    final obj = core.tryJson(txt);
    if (obj is! Map) { _j({'ok': false, 'error': 'not_an_object'}); return 2; }
    final errors = <String>[];
    final warnings = <String>[];
    bool _isListOfStrings(dynamic v) => v is List && v.every((e) => e is String);
    void chkListStr(String key) { if (obj.containsKey(key) && !_isListOfStrings(obj[key])) errors.add('$key must be string[]'); }
    void chkNum(String key) { if (obj.containsKey(key) && int.tryParse((obj[key]?.toString() ?? '')) == null) errors.add('$key must be integer'); }
    for (final k in ['allowlist','denylist','env_allowlist','env_denylist','auto_cli_allowlist']) { chkListStr(k); }
    for (final k in ['default_cli_retries','default_cli_retry_backoff_ms','default_cli_timeout_seconds']) { chkNum(k); }
    if (obj.containsKey('default_cli_on_fail')) {
      final v = (obj['default_cli_on_fail']?.toString() ?? '').toLowerCase().trim();
      if (v != 'stop' && v != 'continue') errors.add('default_cli_on_fail must be "stop" or "continue"');
    }
    if (obj.containsKey('runner_type')) {
      final rt = (obj['runner_type']?.toString() ?? '').toLowerCase().trim();
      if (rt != 'native' && rt != 'web') errors.add('runner_type must be "native" or "web"');
    }
    if (!obj.containsKey('schemaVersion')) {
      warnings.add('schemaVersion is recommended (e.g., "1")');
    } else {
      final sv = obj['schemaVersion'];
      if (sv is! String && sv is! num) warnings.add('schemaVersion should be a string or number');
    }
    final allowedKeys = <String>{
      'schemaVersion',
      'allowlist','denylist','env_allowlist','env_denylist','auto_cli_allowlist',
      'default_cli_retries','default_cli_retry_backoff_ms','default_cli_timeout_seconds','default_cli_on_fail',
      'runner_type'
    };
    try {
      final present = obj.keys.map((e)=> e.toString()).toSet();
      final unknown = present.difference(allowedKeys);
      for (final k in unknown) { warnings.add('unknown key: ' + k); }
    } catch (_) {}
    _j({'ok': errors.isEmpty, 'file': f.path, if (errors.isNotEmpty) 'errors': errors, if (warnings.isNotEmpty) 'warnings': warnings});
    return errors.isEmpty ? 0 : 2;
  } catch (e) {
    _j({'ok': false, 'error': 'validate_failed', 'message': e.toString()});
    return 2;
  }
}

Future<int> handleInitConfig() async {
  const sample = r'''
{
  "schemaVersion": "1",
  "allowlist": ["npm", "pnpm", "yarn", "flutter", "dart"],
  "denylist": ["rm", "sudo", "curl", "wget"],
  "env_allowlist": ["^(SUPABASE|COGO)_"],
  "env_denylist": ["SECRET", "KEY$"],
  "auto_cli_allowlist": ["json-set", "json-merge", "json-remove"],
  "default_cli_retries": 1,
  "default_cli_retry_backoff_ms": 500,
  "default_cli_timeout_seconds": 60,
  "default_cli_on_fail": "stop",
  "runner_type": "native"
}
''';
  try {
    final f = File('.cogo/runner.config.json');
    await f.parent.create(recursive: true);
    if (!await f.exists()) { await f.writeAsString(sample); }
    _j({'ok': true, 'file': f.path});
  } catch (e) {
    _j({'ok': false, 'error': 'init_config_failed', 'message': e.toString()});
    return 2;
  }
  return 0;
}

Future<int> handleSessionSummary(ArgResults c) async {
  try {
    final dir = (c['log-dir']?.toString() ?? '.cogo/session').trim();
    final out = (c['out-json']?.toString() ?? '').trim();
    final outActionsPath = (c['out-actions']?.toString() ?? '').trim();
    final outSummaryPath = (c['out-summary']?.toString() ?? '').trim();
    final d = Directory(dir);
    if (!await d.exists()) { _j({'ok': false, 'error': 'log_dir_not_found', 'dir': dir}); return 2; }
    final summary = {
      'schema': 'session-summary@v1',
      'log_dir': dir,
      'trace_file': await File('$dir/trace_id.txt').exists() ? '$dir/trace_id.txt' : null,
      'steps': <Map<String, dynamic>>[],
      'actions': <String>[],
      'counters': {
        'applied': 0,
        'skipped': 0,
        'error': 0
      },
      if (outActionsPath.isNotEmpty) 'out_actions': outActionsPath,
      if (outSummaryPath.isNotEmpty) 'out_summary': outSummaryPath
    };
    await for (final ent in d.list(recursive: true, followLinks: false)) {
      if (ent is File) {
        final p = ent.path;
        if (p.contains('/step_') && p.endsWith('.json')) {
          try {
            final obj = core.tryJson(await ent.readAsString()) as Map;
            (summary['steps'] as List).add({'path': p, 'data': obj});
          } catch (_) {}
        }
        if (p.contains('/action_') && (p.endsWith('.txt') || p.endsWith('.out.txt'))) {
          (summary['actions'] as List).add(p);
          try {
            final txt = await ent.readAsString();
            final s = (summary['counters'] as Map<String, int>);
            final lc = txt.toLowerCase();
            if (lc.contains('applied')) s['applied'] = (s['applied'] ?? 0) + core.countSubstring(lc, 'applied');
            if (lc.contains('skipped')) s['skipped'] = (s['skipped'] ?? 0) + core.countSubstring(lc, 'skipped');
            if (lc.contains('error')) s['error'] = (s['error'] ?? 0) + core.countSubstring(lc, 'error');
          } catch (_) {}
        }
      }
    }
    try {
      if (outActionsPath.isNotEmpty) {
        final f = File(outActionsPath);
        if (await f.exists()) {
          final obj = core.tryJson(await f.readAsString()) as Map;
          final acts = (obj['actions'] as List?) ?? const [];
          final counters = (summary['counters'] as Map<String, int>);
          for (final a in acts) {
            if (a is! Map) continue;
            final t = (a['type']?.toString() ?? '').toLowerCase();
            if (t == 'apply_edits') {
              final results = (a['results'] as List?) ?? const [];
              for (final r in results) {
                if (r is! Map) continue;
                if (r['applied'] == true) counters['applied'] = (counters['applied'] ?? 0) + 1;
                else if (r['skipped'] == true) counters['skipped'] = (counters['skipped'] ?? 0) + 1;
                else if (r['error'] != null) counters['error'] = (counters['error'] ?? 0) + 1;
              }
            }
          }
        }
      }
    } catch (_) {}
    if (out.isNotEmpty) { core.writeIfPath(out, jsonEncode(summary)); }
    _j({'ok': true, 'summary': summary});
    return 0;
  } catch (e) {
    _j({'ok': false, 'error': 'session_summary_failed', 'message': e.toString()});
    return 2;
  }
}


