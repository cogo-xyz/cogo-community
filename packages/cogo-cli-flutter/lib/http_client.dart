import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class EdgeHttp {
  final String base;
  final String anon;

  EdgeHttp(this.base, this.anon);

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        'Authorization': 'Bearer $anon',
        'apikey': anon,
      };

  Future<http.Response> get(String path) =>
      http.get(Uri.parse(base + path), headers: _headers);

  Future<http.Response> post(String path, String body) =>
      http.post(Uri.parse(base + path), headers: _headers, body: body);

  Future<http.Response> postWithHeaders(String path, String body, {Map<String, String>? headers, Duration? timeout}) async {
    final merged = <String, String>{}..addAll(_headers)..addAll(headers ?? const {});
    final fut = http.post(Uri.parse(base + path), headers: merged, body: body);
    if (timeout != null) {
      return await fut.timeout(timeout);
    }
    return await fut;
  }

  /// POST with Accept: text/event-stream and yield SSE frames via callback
  Future<void> postSse(
    String path,
    String body, {
    Duration? timeout,
    void Function(String event, String data)? onEvent,
  }) async {
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(base + path));
      final headers = Map<String, String>.from(_headers);
      headers['accept'] = 'text/event-stream';
      req.headers.addAll(headers);
      req.body = body;
      final streamed = timeout == null
          ? await client.send(req)
          : await client.send(req).timeout(timeout);
      final lines = streamed.stream.transform(utf8.decoder).transform(const LineSplitter());
      String? curEvent;
      final dataBuf = StringBuffer();
      await for (final line in lines) {
        if (line.isEmpty) {
          if (curEvent != null || dataBuf.isNotEmpty) {
            final ev = curEvent ?? 'message';
            final data = dataBuf.toString();
            onEvent?.call(ev, data);
          }
          curEvent = null;
          dataBuf.clear();
          continue;
        }
        if (line.startsWith(':')) { continue; }
        if (line.startsWith('event:')) {
          curEvent = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          if (dataBuf.isNotEmpty) dataBuf.writeln();
          dataBuf.write(line.substring(5).trim());
        }
      }
      // flush trailing (in case no blank line at end)
      if (curEvent != null || dataBuf.isNotEmpty) {
        onEvent?.call(curEvent ?? 'message', dataBuf.toString());
      }
    } on TimeoutException {
      onEvent?.call('timeout', '{}');
    } finally {
      client.close();
    }
  }

  /// Uploads bytes directly to a signed URL (absolute), returns the HTTP response
  static Future<http.Response> putSignedUrl(
    String signedUrl,
    List<int> bodyBytes, {
    String contentType = 'application/octet-stream',
  }) async {
    final headers = <String, String>{'Content-Type': contentType};
    return await http.put(Uri.parse(signedUrl), headers: headers, body: bodyBytes);
  }

  static String buildBase() {
    final env = Platform.environment;
    var b = env['SUPABASE_EDGE'];
    final pid = env['SUPABASE_PROJECT_ID'];
    if (b == null || b.isEmpty) {
      if (pid != null && pid.isNotEmpty) {
        b = 'https://$pid.functions.supabase.co/functions/v1';
      }
    }
    if (b == null || b.isEmpty) return '';
    if (!b.endsWith('/functions/v1')) {
      if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    }
    return b;
  }
}

Future<void> promptHitl(String message) async {
  stdout.writeln(message + ' [y/N]');
  final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (input != 'y' && input != 'yes') {
    throw Exception('user_aborted');
  }
}

class RunnerConfig {
  final Set<String> allowlist;
  final Set<String> denylist;
  final List<RegExp> envAllow;
  final List<RegExp> envDeny;
  final Set<String> autoCliAllow;
  final int defaultRetries;
  final int defaultBackoffMs;
  final int defaultTimeoutSec;
  final String defaultOnFail; // 'stop' | 'continue'
  final String runnerType; // 'native' | 'web'
  const RunnerConfig({
    required this.allowlist,
    required this.denylist,
    required this.envAllow,
    required this.envDeny,
    required this.autoCliAllow,
    required this.defaultRetries,
    required this.defaultBackoffMs,
    required this.defaultTimeoutSec,
    required this.defaultOnFail,
    required this.runnerType,
  });
}

RunnerConfig loadRunnerConfig() {
  try {
    final f = File('.cogo/runner.config.json');
    if (!f.existsSync()) {
      return const RunnerConfig(allowlist: {
        'npm','pnpm','yarn','flutter','dart',
        'json-set','json-merge','json-remove'
      }, denylist: { }, envAllow: [], envDeny: [], autoCliAllow: {'json-set','json-merge','json-remove'}, defaultRetries: 0, defaultBackoffMs: 500, defaultTimeoutSec: 0, defaultOnFail: 'stop', runnerType: 'native');
    }
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map) return const RunnerConfig(allowlist: {}, denylist: {}, envAllow: [], envDeny: [], autoCliAllow: {}, defaultRetries: 0, defaultBackoffMs: 500, defaultTimeoutSec: 0, defaultOnFail: 'stop', runnerType: 'native');
    final a = (obj['allowlist'] is List) ? Set<String>.from((obj['allowlist'] as List).map((e)=> e.toString())) : <String>{};
    final d = (obj['denylist'] is List) ? Set<String>.from((obj['denylist'] as List).map((e)=> e.toString())) : <String>{};
    List<RegExp> envAllow = [];
    List<RegExp> envDeny = [];
    try { envAllow = (obj['env_allowlist'] as List? ?? []).map((e)=> RegExp(e.toString())).toList(); } catch (_) {}
    try { envDeny = (obj['env_denylist'] as List? ?? []).map((e)=> RegExp(e.toString())).toList(); } catch (_) {}
    Set<String> autoAllow = {};
    try { autoAllow = Set<String>.from(((obj['auto_cli_allowlist'] as List?) ?? []).map((e)=> e.toString())); } catch (_) {}
    int defRetries = 0;
    int defBackoff = 500;
    int defTimeout = 0;
    try { defRetries = int.tryParse((obj['default_cli_retries']?.toString() ?? '').trim()) ?? 0; } catch (_) {}
    try { defBackoff = int.tryParse((obj['default_cli_retry_backoff_ms']?.toString() ?? '').trim()) ?? 500; } catch (_) {}
    try { defTimeout = int.tryParse((obj['default_cli_timeout_seconds']?.toString() ?? '').trim()) ?? 0; } catch (_) {}
    String defOnFail = 'stop';
    try {
      final s = (obj['default_cli_on_fail']?.toString() ?? '').trim().toLowerCase();
      if (s == 'stop' || s == 'continue') defOnFail = s;
    } catch (_) {}
    String runnerType = 'native';
    try {
      final rt = (obj['runner_type']?.toString() ?? '').trim().toLowerCase();
      if (rt == 'web' || rt == 'native') runnerType = rt;
    } catch (_) {}
    return RunnerConfig(allowlist: a, denylist: d, envAllow: envAllow, envDeny: envDeny, autoCliAllow: autoAllow, defaultRetries: defRetries, defaultBackoffMs: defBackoff, defaultTimeoutSec: defTimeout, defaultOnFail: defOnFail, runnerType: runnerType);
  } catch (_) {
    return const RunnerConfig(allowlist: {}, denylist: {}, envAllow: [], envDeny: [], autoCliAllow: {}, defaultRetries: 0, defaultBackoffMs: 500, defaultTimeoutSec: 0, defaultOnFail: 'stop', runnerType: 'native');
  }
}

String _maskSecrets(String input) {
  String s = input;
  final patterns = <RegExp>[
    RegExp(r'(secret|token|password|api[_-]?key)\s*[:=]\s*[^\s]+', caseSensitive: false),
    RegExp(r'eyJ[\w-]{10,}'), // JWT-like
    RegExp(r'[A-Za-z0-9_-]{32,}'), // generic long tokens
  ];
  for (final re in patterns) {
    s = s.replaceAllMapped(re, (m) {
      final text = m.group(0) ?? '';
      final idxEq = text.indexOf('=');
      final idxCol = text.indexOf(':');
      if (idxEq > 0) return text.substring(0, idxEq + 1) + ' <REDACTED>';
      if (idxCol > 0) return text.substring(0, idxCol + 1) + ' <REDACTED>';
      return '<REDACTED>';
    });
  }
  return s;
}

bool matchIncludeExclude(String path, String includeGlob, String excludeGlob) {
  if (includeGlob.isNotEmpty && !path.contains(includeGlob)) return false;
  if (excludeGlob.isNotEmpty && path.contains(excludeGlob)) return false;
  return true;
}

Future<Map<String, dynamic>> dispatchNextActions(List actions, {required bool hitl, required bool auto, String? logDir, EdgeHttp? http, String? traceId, String includeGlob = '', String excludeGlob = ''}) async {
  final cfg = loadRunnerConfig();
  final summary = <Map<String, dynamic>>[];
  for (final a in actions) {
    if (a is! Map) continue;
    final type = (a['type']?.toString() ?? '').toLowerCase();
    if (type == 'cli') {
      // Web runner forbids process execution
      if (cfg.runnerType == 'web') {
        if ((logDir ?? '').isNotEmpty) {
          try { final dir = Directory(logDir!); await dir.create(recursive: true); File('${logDir}/skipped_${DateTime.now().millisecondsSinceEpoch}.txt').writeAsStringSync('Skipped CLI (runner_type=web)'); } catch (_) {}
        }
        summary.add({'type': 'cli', 'skipped': true, 'reason': 'runner_type=web', 'cmd': a['cmd']});
        continue;
      }
      final cmd = (a['cmd']?.toString() ?? '').trim();
      final args = (a['args'] is List) ? (a['args'] as List).map((e)=> e.toString()).toList() : <String>[];
      final cwd = (a['cwd']?.toString() ?? '').trim();
      final needsHitl = a['hitl'] == true;
      final actionDryRun = a['dry_run'] == true;
      // allow/deny evaluation
      if (cfg.denylist.contains(cmd)) {
        String? logPath;
        if ((logDir ?? '').isNotEmpty) {
          try {
            final dir = Directory(logDir!); await dir.create(recursive: true);
            final ts = DateTime.now().millisecondsSinceEpoch;
            logPath = '${logDir}/denied_${ts}.txt';
            File(logPath).writeAsStringSync('Denied command: ' + cmd);
          } catch (_) {}
        }
        summary.add({'type': 'cli', 'denied': true, 'cmd': cmd, if (logPath != null) 'log_files': [logPath]});
        continue;
      }
      if (cfg.allowlist.isNotEmpty && !cfg.allowlist.contains(cmd)) {
        // skip non-allowed command for safety
        String? logPath;
        if ((logDir ?? '').isNotEmpty) {
          try {
            final dir = Directory(logDir!); await dir.create(recursive: true);
            final ts = DateTime.now().millisecondsSinceEpoch;
            logPath = '${logDir}/skipped_${ts}.txt';
            File(logPath).writeAsStringSync('Skipped command (not in allowlist): ' + cmd);
          } catch (_) {}
        }
        summary.add({'type': 'cli', 'skipped': true, 'reason': 'not_in_allowlist', 'cmd': cmd, if (logPath != null) 'log_files': [logPath]});
        continue;
      }
      // auto-bypass prompt for safe JSON CRUD commands
      final isAutoSafe = cfg.autoCliAllow.contains(cmd) || ((cmd == 'cogo_cli_flutter' || cmd == 'cogo-cli-flutter') && args.isNotEmpty && cfg.autoCliAllow.contains(args.first));
      if ((hitl || needsHitl) && !isAutoSafe) {
        await promptHitl('Run: ' + ([cmd, ...args].join(' ')) + (cwd.isNotEmpty ? ' (cwd: '+cwd+')' : ''));
      }
      // timeout/env handling
      int timeoutSec = int.tryParse((a['timeout']?.toString() ?? '').trim()) ?? 0;
      if (timeoutSec <= 0) timeoutSec = cfg.defaultTimeoutSec;
      Map<String, String>? env;
      if (a['env'] is Map) {
        final raw = (a['env'] as Map).map((k,v)=> MapEntry(k.toString(), v.toString()));
        // filter env by allow/deny patterns
        Map<String, String> filtered = {};
        raw.forEach((k,v) {
          final denied = cfg.envDeny.any((re)=> re.hasMatch(k));
          if (denied) return;
          if (cfg.envAllow.isNotEmpty) {
            final allowed = cfg.envAllow.any((re)=> re.hasMatch(k));
            if (!allowed) return;
          }
          filtered[k] = v;
        });
        env = filtered;
      }
      if (actionDryRun) {
        String? logPath;
        if ((logDir ?? '').isNotEmpty) {
          try {
            final dir = Directory(logDir!); await dir.create(recursive: true);
            final ts = DateTime.now().millisecondsSinceEpoch;
            logPath = '${logDir}/dry_run_${ts}.txt';
            File(logPath).writeAsStringSync('Would run: ' + ([cmd, ...args].join(' ')));
          } catch (_) {}
        }
        summary.add({'type': 'cli', 'dry_run': true, 'cmd': cmd, 'args': args, if (cwd.isNotEmpty) 'cwd': cwd, if (logPath != null) 'log_files': [logPath]});
        continue;
      }

      ProcessResult pr;
      final List<String> cliLogFiles = [];
      int attempt = 0;
      int maxRetries = int.tryParse((a['retries']?.toString() ?? '').trim()) ?? -1;
      if (maxRetries < 0) maxRetries = cfg.defaultRetries;
      int backoffMs = int.tryParse((a['retry_backoff_ms']?.toString() ?? '').trim()) ?? -1;
      if (backoffMs < 0) backoffMs = cfg.defaultBackoffMs;
      while (true) {
        attempt++;
        try {
          final fut = Process.run(cmd, args, workingDirectory: cwd.isNotEmpty ? cwd : null, environment: env);
          pr = (timeoutSec > 0)
            ? await fut.timeout(Duration(seconds: timeoutSec))
            : await fut;
        } on TimeoutException {
          pr = ProcessResult(0, 124, '', 'timeout');
        }
        if ((logDir ?? '').isNotEmpty) {
          try {
            final dir = Directory(logDir!); await dir.create(recursive: true);
            final ts = DateTime.now().millisecondsSinceEpoch;
            final combined = ((pr.stdout?.toString() ?? '') + (pr.stderr?.toString() ?? '')).trim();
            final path = '${logDir}/action_${ts}_attempt${attempt}.out.txt';
            File(path).writeAsStringSync(_maskSecrets(combined));
            cliLogFiles.add(path);
          } catch (_) {}
        }
        if (pr.exitCode == 0 || attempt > maxRetries) break;
        await Future<void>.delayed(Duration(milliseconds: backoffMs));
      }
      final out = (pr.stdout?.toString() ?? '').trim();
      final err = (pr.stderr?.toString() ?? '').trim();
      if ((logDir ?? '').isNotEmpty) {
        try {
          final dir = Directory(logDir!); await dir.create(recursive: true);
          final ts = DateTime.now().millisecondsSinceEpoch;
          final path = '${logDir}/action_${ts}.out.txt';
          File(path).writeAsStringSync(_maskSecrets(out + (err.isEmpty ? '' : '\n' + err)));
          cliLogFiles.add(path);
        } catch (_) {}
      }
      String onFail = (a['on_fail']?.toString() ?? '').toLowerCase();
      if (onFail != 'stop' && onFail != 'continue') onFail = cfg.defaultOnFail;
      if (pr.exitCode != 0 && onFail == 'stop') {
        summary.add({'type': 'cli', 'cmd': cmd, 'args': args, if (cwd.isNotEmpty) 'cwd': cwd, 'exit_code': pr.exitCode, 'failed': true, if (cliLogFiles.isNotEmpty) 'log_files': cliLogFiles});
        throw Exception('cli_action_failed: $cmd (${pr.exitCode})');
      }
      summary.add({'type': 'cli', 'cmd': cmd, 'args': args, if (cwd.isNotEmpty) 'cwd': cwd, 'exit_code': pr.exitCode, if (cliLogFiles.isNotEmpty) 'log_files': cliLogFiles});
    } else if (type == 'apply_edits') {
      // Web runner forbids local file writes
      if (cfg.runnerType == 'web') {
        if ((logDir ?? '').isNotEmpty) {
          try { final dir = Directory(logDir!); await dir.create(recursive: true); File('${logDir}/skipped_${DateTime.now().millisecondsSinceEpoch}.txt').writeAsStringSync('Skipped apply_edits (runner_type=web)'); } catch (_) {}
        }
        summary.add({'type': 'apply_edits', 'skipped': true, 'reason': 'runner_type=web'});
        continue;
      }
      if (hitl) { await promptHitl('Apply edits from agent?'); }
      // Attempt to fetch edits from current trace if not inlined
      List edits = [];
      if (a['edits'] is List) { edits = a['edits']; }
      else if (http != null && (traceId ?? '').isNotEmpty) {
        try {
          final r = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(traceId!));
          final obj = jsonDecode(r.body);
          if (obj is Map && obj['edits'] is List) edits = obj['edits'];
        } catch (_) {}
      }
      final List<Map<String, dynamic>> results = [];
      for (final e in edits) {
        if (e is! Map) continue;
        final p = (e['path']?.toString() ?? '').trim();
        final content = e['content']?.toString() ?? '';
        if (p.isEmpty) continue;
        // simple include/exclude filter
        if (!matchIncludeExclude(p, includeGlob, excludeGlob)) { results.add({'path': p, 'skipped': true, 'reason': 'filtered'}); continue; }
        try {
          final f = File(p); await f.parent.create(recursive: true); await f.writeAsString(content);
          results.add({'path': p, 'applied': true});
        } catch (err) {
          results.add({'path': p, 'error': err.toString()});
        }
      }
      summary.add({'type': 'apply_edits', 'count': (edits.length), 'results': results});
    } else if (type == 'git_ops') {
      // Out of current scope: treat as skipped with reason
      summary.add({'type': 'git_ops', 'skipped': true, 'reason': 'out_of_scope'});
    }
  }
  return {'actions': summary};
}


