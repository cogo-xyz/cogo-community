#!/usr/bin/env dart
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:cogo_cli_flutter/http_client.dart';
import 'package:cogo_cli_flutter/core/utils.dart' as core;
import 'package:cogo_cli_flutter/core/diff.dart' as diff;
import 'package:cogo_cli_flutter/commands/trace.dart' as trace_cmd;
import 'package:cogo_cli_flutter/commands/chat.dart' as chat_cmd;
import 'package:cogo_cli_flutter/commands/artifacts.dart' as artifacts_cmd;
import 'package:cogo_cli_flutter/commands/files.dart' as files_cmd;
import 'package:cogo_cli_flutter/commands/json.dart' as json_cmd;
import 'package:cogo_cli_flutter/commands/config.dart' as config_cmd;
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
  // Trace group (status/logs/open)
  final trace = ArgParser();
  final tStatus = ArgParser()
    ..addOption('trace-id', help: 'Trace ID')
    ..addFlag('watch', negatable: false, help: 'Watch until ready')
    ..addOption('interval-seconds', defaultsTo: '2')
    ..addOption('timeout-seconds', defaultsTo: '60')
    ..addFlag('show-progress', negatable: false, help: 'Print events_count and last_event_at while watching');
  trace.addCommand('status', tStatus);
  final tLogs = ArgParser()
    ..addOption('trace-id', help: 'Trace ID')
    ..addFlag('watch', negatable: false, help: 'Watch logs periodically')
    ..addOption('interval-seconds', defaultsTo: '3')
    ..addOption('max-errors', defaultsTo: '5')
    ..addOption('retry-backoff-ms', defaultsTo: '500')
    ..addFlag('show-progress', negatable: false, help: 'Show progress bar and elapsed time while watching');
  trace.addCommand('logs', tLogs);
  final tOpen = ArgParser()
    ..addOption('trace-id', help: 'Trace ID')
    ..addOption('url', help: 'Override URL')
    ..addOption('browser', help: 'Browser/launcher command; overrides env BROWSER');
  trace.addCommand('open', tOpen);
  p.addCommand('trace', trace);
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
  // Chat gateway (new)
  final send = ArgParser()
    ..addOption('message')
    ..addOption('agent-id')
    ..addOption('task-type')
    ..addOption('intent')
    ..addOption('lang')
    ..addOption('body-file')
    ..addFlag('wait', negatable: false)
    ..addOption('timeout-seconds');
  p.addCommand('chat-send', send);

  // chat-stream (SSE)
  final stream = ArgParser()
    ..addOption('message')
    ..addOption('timeout-seconds', defaultsTo: '60')
    ..addOption('body-file')
    ..addOption('retry', defaultsTo: '0', help: 'Retry count on failure')
    ..addOption('retry-backoff-ms', help: 'Base backoff milliseconds between retries (defaults to config)')
    ..addOption('abort-after-ms', help: 'Abort stream after N ms')
    ..addOption('out-summary', help: 'Write stream summary JSON to file');
  p.addCommand('chat-stream', stream);

  final loop = ArgParser()
    ..addOption('message')
    ..addOption('agent-id')
    ..addOption('task-type')
    ..addOption('intent')
    ..addOption('lang')
    ..addOption('body-file')
    ..addFlag('hitl', negatable: false)
    ..addFlag('auto', negatable: false)
    ..addOption('max-steps', defaultsTo: '5')
    ..addOption('resume')
    ..addOption('timeout-seconds', defaultsTo: '20')
    ..addOption('step-retries', defaultsTo: '0')
    ..addOption('step-retry-backoff-ms', defaultsTo: '500')
    ..addOption('log-dir')
    ..addOption('out-summary')
    ..addOption('out-actions')
    ..addOption('include-glob')
    ..addOption('exclude-glob')
    ..addOption('followup-body-file')
    ..addOption('followup-message');
  p.addCommand('chat-loop', loop);

  final fc = ArgParser()
    ..addOption('since', help: 'Git ref, e.g., HEAD~1')
    ..addOption('base', help: 'Base ref to diff against')
    ..addFlag('staged', negatable: false, help: 'Use --cached')
    ..addFlag('name-only', negatable: false, help: 'Print only filenames')
    ..addFlag('name-status', negatable: false, help: 'Print name and status (A/M/D/R...)')
    ..addFlag('stat', negatable: false, help: 'Show shortstat summary')
    ..addFlag('json', negatable: false, help: 'Emit JSON output');
  p.addCommand('files-changed', fc);
  // apply-edits (stub)
  final ap = ArgParser()
    ..addOption('trace-id', mandatory: true)
    ..addFlag('dry-run', negatable: false)
    ..addFlag('preview', negatable: false, help: 'Show unified diff preview before apply')
    ..addFlag('color', negatable: false, help: 'Colorize diff output')
    ..addOption('preview-max-lines', help: 'Limit preview lines per file (0=all)', defaultsTo: '0')
    ..addOption('include-glob')
    ..addOption('exclude-glob')
    ..addFlag('hitl', negatable: false)
    ..addFlag('hitl-all', negatable: false, help: 'Single approval to apply all edits')
    ..addOption('backup-dir', help: 'Directory to save backups of existing files')
    ..addFlag('backup-default', negatable: false, help: 'Use .cogo/backups as backup dir when not specified')
    ..addOption('skip-large-bytes', help: 'Skip edits larger than N bytes (0=disabled)', defaultsTo: '0')
    ..addFlag('skip-binary', negatable: false, help: 'Skip edits targeting likely-binary files');
  p.addCommand('apply-edits', ap);
  // apply-restore
  final ar = ArgParser()
    ..addOption('file', help: 'Original file path to restore', mandatory: true)
    ..addOption('backup-dir', help: 'Backups base directory (default .cogo/backups)')
    ..addFlag('list', negatable: false, help: 'List available backups and exit')
    ..addOption('ts', help: 'Restore backup with specified timestamp suffix')
    ..addFlag('latest', negatable: false, help: 'Restore latest backup when --ts not provided')
    ..addFlag('dry-run', negatable: false);
  p.addCommand('apply-restore', ar);
  // chat-result (alias for trace-status with optional polling)
  final cr = ArgParser()
    ..addOption('trace-id')
    ..addOption('timeout-seconds');
  p.addCommand('chat-result', cr);
  // init-config: write default runner config
  p.addCommand('init-config');
  // session-summary: aggregate logs in a session dir
  final sess = ArgParser()
    ..addOption('log-dir', help: 'Session/log directory', defaultsTo: '.cogo/session')
    ..addOption('out-json', help: 'Write summary to file')
    ..addOption('out-actions', help: 'Path to out-actions JSON (optional)')
    ..addOption('out-summary', help: 'Path to out-summary JSON (optional)');
  p.addCommand('session-summary', sess);
  final flow = ArgParser()
    ..addOption('file', help: 'Path to a local JSON file to upload', defaultsTo: 'sample.json')
    ..addOption('timeout', help: 'Poll timeout seconds', defaultsTo: '20');
  p.addCommand('attachments-flow', flow);
  // artifacts: upload/download (aliases around attachments)
  final artUp = ArgParser()
    ..addOption('file', mandatory: true, help: 'Local file to upload')
    ..addOption('out-key', help: 'Write generated storage key');
  p.addCommand('artifacts-upload', artUp);
  final artDown = ArgParser()
    ..addOption('trace-id', help: 'Trace ID')
    ..addOption('signed-url', help: 'Signed URL')
    ..addOption('out-file', help: 'Output path', defaultsTo: 'artifact.bin');
  p.addCommand('artifacts-download', artDown);
  // artifacts batch/list/rm (local helpers)
  final artUpBatch = ArgParser()
    ..addOption('retry', defaultsTo: '0')
    ..addOption('retry-backoff-ms', defaultsTo: '500')
    ..addOption('concurrency', defaultsTo: '2', help: 'Number of parallel uploads');
  p.addCommand('artifacts-upload-batch', artUpBatch); // positional files
  final artList = ArgParser()
    ..addOption('log-dir', help: 'Session/log directory', mandatory: true)
    ..addOption('pattern', help: 'Substring filter (optional)')
    ..addFlag('json', negatable: false, help: 'Emit JSON');
  p.addCommand('artifacts-list', artList);
  final artRm = ArgParser()
    ..addOption('log-dir', help: 'Session/log directory', mandatory: true)
    ..addOption('pattern', help: 'Substring filter (required)', mandatory: true)
    ..addFlag('dry-run', negatable: false);
  p.addCommand('artifacts-rm', artRm);
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
  // config-validate
  p.addCommand('config-validate');
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
    case 'config-validate':
      return await config_cmd.handleConfigValidate();
    case 'chat-stream':
      {
        final bodyFile = (c['body-file']?.toString() ?? '').trim();
        Map<String, dynamic> bodyMap;
        if (bodyFile.isNotEmpty) {
          try {
            final txt = File(bodyFile).readAsStringSync();
            bodyMap = _tryJson(txt) as Map<String, dynamic>;
          } catch (e) {
            j({'ok': false, 'error': 'body_file_read_error', 'message': e.toString()});
            return 2;
          }
        } else {
          final msg = (c['message']?.toString() ?? '').trim();
          if (msg.isEmpty) { j({'ok': false, 'error': 'message_or_body_required'}); return 2; }
          bodyMap = { 'projectId': _projectId(ar), 'text': msg };
        }
        final cfg = loadRunnerConfig();
        final timeout = int.tryParse((c['timeout-seconds']?.toString() ?? (cfg.defaultTimeoutSec.toString()))) ?? cfg.defaultTimeoutSec;
        final retry = int.tryParse((c['retry']?.toString() ?? (cfg.defaultRetries.toString()))) ?? cfg.defaultRetries;
        final abortMs = int.tryParse((c['abort-after-ms']?.toString() ?? '0')) ?? 0;
        int attempt = 0;
        while (true) {
          final frames = <Map<String, dynamic>>[];
          int deltaCount = 0;
          final started = DateTime.now();
          try {
            await http.postSse('/chat', jsonEncode(bodyMap), timeout: Duration(seconds: timeout), onEvent: (ev, data) {
              if (abortMs > 0 && DateTime.now().difference(started).inMilliseconds >= abortMs) {
                throw Exception('aborted_by_client');
              }
              Map o;
              try { o = _tryJson(data) as Map; } catch (_) { o = {'text': data}; }
              frames.add({'event': ev, 'data': o});
              if (ev.contains('delta')) { deltaCount++; if (deltaCount % 8 == 0) stdout.write('.'); }
            });
            stdout.writeln('');
            final durationMs = DateTime.now().difference(started).inMilliseconds;
            final summary = {'ok': true, 'domain': 'sdk', 'action': 'chat-stream', 'frames': frames, 'deltas': deltaCount, 'duration_ms': durationMs};
            final outSummary = (c['out-summary']?.toString() ?? '').trim();
            if (outSummary.isNotEmpty) { _writeIfPath(outSummary, jsonEncode(summary)); }
            j(summary);
            return 0;
          } catch (e) {
            attempt++;
            if (attempt > retry) {
              final durationMs = DateTime.now().difference(started).inMilliseconds;
              final outSummary = (c['out-summary']?.toString() ?? '').trim();
              if (outSummary.isNotEmpty) {
                final fail = {'ok': false, 'error': e.toString(), 'attempts': attempt, 'duration_ms': durationMs};
                _writeIfPath(outSummary, jsonEncode(fail));
              }
              j({'ok': false, 'error': 'sse_failed', 'message': e.toString(), 'attempts': attempt});
              return 2;
            }
            final baseBackoff = int.tryParse((c['retry-backoff-ms']?.toString() ?? (cfg.defaultBackoffMs.toString()))) ?? cfg.defaultBackoffMs;
            final backoffMs = baseBackoff * attempt;
            await Future<void>.delayed(Duration(milliseconds: backoffMs));
          }
        }
      }
    case 'trace':
      {
        final rc = await trace_cmd.handleTrace(http, c, base);
        return rc;
      }
    case 'chat-send':
      return await chat_cmd.handleChatSend(http, ar, c);
    case 'chat-loop':
      {
        // Step-chained loop
        final cfg = loadRunnerConfig();
        final timeout = int.tryParse((c['timeout-seconds']?.toString() ?? (cfg.defaultTimeoutSec.toString()))) ?? cfg.defaultTimeoutSec;
        final stepsMax = int.tryParse((c['max-steps']?.toString() ?? '5')) ?? 5;
        final logDir = (c['log-dir']?.toString() ?? '').trim();
        String traceId = (c['resume']?.toString() ?? '').trim();
        if (traceId.isEmpty) {
          final msg = (c['message']?.toString() ?? '').trim();
          final bodyMap = (msg.isNotEmpty)
              ? {
                  'projectId': _projectId(ar),
                  if ((c['agent-id']?.toString() ?? '').trim().isNotEmpty) 'agentId': c['agent-id']?.toString().trim(),
                  if ((c['task-type']?.toString() ?? '').trim().isNotEmpty) 'task_type': c['task-type']?.toString().trim(),
                  if ((c['intent']?.toString() ?? '').trim().isNotEmpty) 'intent': c['intent']?.toString().trim(),
                  if ((c['lang']?.toString() ?? '').trim().isNotEmpty) 'lang': c['lang']?.toString().trim(),
                  'text': msg,
                }
              : (c['body-file']?.toString() ?? '').trim().isNotEmpty
                  ? (_tryJson(File((c['body-file']?.toString() ?? '').trim()).readAsStringSync()) as Map<String, dynamic>)
                  : <String, dynamic>{'projectId': _projectId(ar), 'text': 'hello'};
          final r = await http.post('/chat-gateway', jsonEncode(bodyMap));
          final obj = _tryJson(r.body) as Map;
          traceId = obj['trace_id']?.toString() ?? '';
          if (traceId.isEmpty) { j({'ok': false, 'error': 'trace_id_missing', 'result': obj}); return 2; }
        }
        if (logDir.isNotEmpty) {
          try { await Directory(logDir).create(recursive: true); File('$logDir/trace_id.txt').writeAsStringSync(traceId); } catch (_) {}
        }
        final hitl = (c['hitl'] == true);
        final auto = (c['auto'] == true);
        final outSummary = (c['out-summary']?.toString() ?? '').trim();
        String endedReason = '';
        final stepRetries = int.tryParse((c['step-retries']?.toString() ?? '0')) ?? 0;
        final stepBackoffMs = int.tryParse((c['step-retry-backoff-ms']?.toString() ?? '500')) ?? 500;
        final List<Map<String, dynamic>> stepSummaries = [];
        for (int step = 1; step <= stepsMax; step++) {
          int attempt = 0;
          bool stepDone = false;
          final stepStart = DateTime.now();
          while (!stepDone) {
            attempt++;
            final started = DateTime.now();
            Map ro = const {};
            while (true) {
              final rr = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(traceId));
              ro = _tryJson(rr.body) as Map;
              final status = (ro['status']?.toString() ?? '');
              if (status == 'ready' || status == 'failed') break;
              if (DateTime.now().difference(started).inSeconds >= timeout) break;
              await Future<void>.delayed(const Duration(seconds: 2));
            }
            if ((ro['status']?.toString() ?? '') == 'ready') {
              final actions = (ro['next_actions'] is List) ? (ro['next_actions'] as List) : const [];
              j({'ok': true, 'domain': 'sdk', 'action': 'chat-loop', 'status': 200, 'trace_id': traceId, 'step': step, 'next_actions': actions});
              final stepDurationMs = DateTime.now().difference(stepStart).inMilliseconds;
              stepSummaries.add({'step': step, 'trace_id': traceId, 'status': 'ready', 'attempts': attempt, 'duration_ms': stepDurationMs, 'actions_count': actions.length, 'actions': actions});
              if (logDir.isNotEmpty) {
                try {
                  final ts = DateTime.now().millisecondsSinceEpoch;
                  File('$logDir/step_${ts}.json').writeAsStringSync(jsonEncode({'step': step, 'trace_id': traceId, 'next_actions': actions}));
                } catch (_) {}
              }
              final actSummary = await dispatchNextActions(
                actions,
                hitl: hitl,
                auto: auto,
                logDir: logDir,
                http: http,
                traceId: traceId,
                includeGlob: (c['include-glob']?.toString() ?? '').trim(),
                excludeGlob: (c['exclude-glob']?.toString() ?? '').trim(),
              );
              final outActions = (c['out-actions']?.toString() ?? '').trim();
              if (outActions.isNotEmpty) {
                try { File(outActions).writeAsStringSync(jsonEncode(actSummary)); } catch (_) {}
              }
              stepDone = true;
            } else {
              if (attempt > stepRetries) {
                final stepDurationMs = DateTime.now().difference(stepStart).inMilliseconds;
                stepSummaries.add({'step': step, 'trace_id': traceId, 'status': 'timeout_or_failed', 'attempts': attempt, 'duration_ms': stepDurationMs});
                j({'ok': true, 'domain': 'sdk', 'action': 'chat-loop', 'status': 200, 'trace_id': traceId, 'step': step, 'timeout_or_failed': true, 'attempts': attempt});
                if (outSummary.isNotEmpty) {
                  endedReason = 'timeout_or_failed';
                  final m = {
                    'trace_id': traceId,
                    'steps': stepSummaries,
                    'ended_reason': endedReason,
                    'log_dir': logDir.isNotEmpty ? logDir : null,
                    'trace_file': logDir.isNotEmpty ? ('$logDir/trace_id.txt') : null,
                  };
                  _writeIfPath(outSummary, jsonEncode(m));
                }
                return 0;
              }
              await Future<void>.delayed(Duration(milliseconds: stepBackoffMs));
            }
          }
          if (!auto || step == stepsMax) {
            if (outSummary.isNotEmpty) {
              endedReason = step == stepsMax ? 'max_steps_reached' : 'completed';
              final m = {
                'trace_id': traceId,
                'steps': stepSummaries,
                'ended_reason': endedReason,
                'log_dir': logDir.isNotEmpty ? logDir : null,
                'trace_file': logDir.isNotEmpty ? ('$logDir/trace_id.txt') : null,
              };
              _writeIfPath(outSummary, jsonEncode(m));
            }
            return 0;
          }
          // Follow-up request body customization
          final fuFile = (c['followup-body-file']?.toString() ?? '').trim();
          final fuMsg = (c['followup-message']?.toString() ?? '').trim();
          Map<String, dynamic> follow;
          if (fuFile.isNotEmpty && fuMsg.isNotEmpty) {
            // Merge rule: file JSON is base; message overrides/sets 'text'
            try {
              follow = (_tryJson(File(fuFile).readAsStringSync()) as Map<String, dynamic>);
            } catch (_) {
              follow = {'projectId': _projectId(ar)};
            }
            follow['projectId'] = follow['projectId'] ?? _projectId(ar);
            follow['text'] = fuMsg;
          } else if (fuFile.isNotEmpty) {
            try { follow = (_tryJson(File(fuFile).readAsStringSync()) as Map<String, dynamic>); }
            catch (_) { follow = {'projectId': _projectId(ar), 'text': 'continue'}; }
            follow['projectId'] = follow['projectId'] ?? _projectId(ar);
            follow['text'] = follow['text'] ?? 'continue';
          } else if (fuMsg.isNotEmpty) {
            follow = {'projectId': _projectId(ar), 'text': fuMsg};
          } else {
            follow = {'projectId': _projectId(ar), 'text': 'continue'};
          }
          // propagate selectors if provided
          if ((c['agent-id']?.toString() ?? '').trim().isNotEmpty) follow['agentId'] = c['agent-id']?.toString().trim();
          if ((c['task-type']?.toString() ?? '').trim().isNotEmpty) follow['task_type'] = c['task-type']?.toString().trim();
          if ((c['intent']?.toString() ?? '').trim().isNotEmpty) follow['intent'] = c['intent']?.toString().trim();
          if ((c['lang']?.toString() ?? '').trim().isNotEmpty) follow['lang'] = c['lang']?.toString().trim();
          final r2 = await http.post('/chat-gateway', jsonEncode(follow));
          final obj2 = _tryJson(r2.body) as Map;
          final newTid = obj2['trace_id']?.toString() ?? '';
          if (newTid.isEmpty) {
            if (outSummary.isNotEmpty) {
              endedReason = 'no_followup_trace';
              final m = {
                'trace_id': traceId,
                'steps': stepSummaries,
                'ended_reason': endedReason,
                'log_dir': logDir.isNotEmpty ? logDir : null,
                'trace_file': logDir.isNotEmpty ? ('$logDir/trace_id.txt') : null,
              };
              _writeIfPath(outSummary, jsonEncode(m));
            }
            return 0;
          }
          traceId = newTid;
          if (logDir.isNotEmpty) { try { File('$logDir/trace_id.txt').writeAsStringSync(traceId); } catch (_) {} }
        }
        if (outSummary.isNotEmpty) {
          if (endedReason.isEmpty) endedReason = 'completed';
          final m = {
            'trace_id': traceId,
            'steps': stepSummaries,
            'ended_reason': endedReason,
            'log_dir': logDir.isNotEmpty ? logDir : null,
            'trace_file': logDir.isNotEmpty ? ('$logDir/trace_id.txt') : null,
          };
          _writeIfPath(outSummary, jsonEncode(m));
        }
        return 0;
      }
    case 'files-changed':
      return await files_cmd.handleFilesChanged(c);
    case 'chat-result':
      return await chat_cmd.handleChatResult(http, c);
    case 'init-config':
      return await config_cmd.handleInitConfig();
    case 'apply-edits':
      {
        // Fetch result for trace and apply simple edits: { path, content }
        final tid = (c['trace-id']?.toString() ?? '').trim();
        if (tid.isEmpty) { j({'ok': false, 'error': 'trace_id_required'}); return 2; }
        final dry = (c['dry-run'] == true);
        final preview = (c['preview'] == true);
        final color = (c['color'] == true);
        final previewMax = int.tryParse((c['preview-max-lines']?.toString() ?? '0')) ?? 0;
        final inc = (c['include-glob']?.toString() ?? '').trim();
        final exc = (c['exclude-glob']?.toString() ?? '').trim();
        final hitl = (c['hitl'] == true);
        String backupDir = (c['backup-dir']?.toString() ?? '').trim();
        final backupDefault = (c['backup-default'] == true);
        if (backupDir.isEmpty && backupDefault) backupDir = '.cogo/backups';
        final hitlAll = (c['hitl-all'] == true);
        final skipLarge = int.tryParse((c['skip-large-bytes']?.toString() ?? '0')) ?? 0;
        final skipBinary = (c['skip-binary'] == true);

        final r = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(tid));
        final obj = _tryJson(r.body) as Map;
        final edits = (obj['edits'] is List) ? (obj['edits'] as List) : const [];
        if (edits.isEmpty) { j({'ok': true, 'domain': 'sdk', 'action': 'apply-edits', 'trace_id': tid, 'applied': 0, 'note': 'no_edits'}); return 0; }

        int considered = 0; int applied = 0; final List<Map<String, dynamic>> summary = [];
        if (hitl && hitlAll) {
          try { await promptHitl('Apply ALL edits?'); } catch (_) { j({'ok': true, 'domain': 'sdk', 'action': 'apply-edits', 'trace_id': tid, 'applied': 0, 'note': 'user_aborted_all'}); return 0; }
        }
        for (final e in edits) {
          if (e is! Map) continue;
          final p = (e['path']?.toString() ?? '').trim();
          final content = e['content']?.toString() ?? '';
          if (p.isEmpty) continue;
          considered++;
          if (!matchIncludeExclude(p, inc, exc)) {
            summary.add({'path': p, 'skipped': true, 'reason': 'filtered'});
            continue;
          }
          if (skipLarge > 0 && content.length > skipLarge) {
            summary.add({'path': p, 'skipped': true, 'reason': 'too_large', 'bytes': content.length});
            continue;
          }
          if (skipBinary && core.looksBinaryPath(p)) {
            summary.add({'path': p, 'skipped': true, 'reason': 'binary_like'});
            continue;
          }
          // Preview unified diff if requested
          if (preview) {
            try {
              final existing = await File(p).exists() ? await File(p).readAsString() : '';
              final diffTxt = diff.unifiedDiff(existing, content, filePath: p, color: color);
              stdout.writeln('===== ' + p + ' =====');
              if (previewMax > 0) {
                final lines = diffTxt.split('\n');
                final take = lines.take(previewMax).join('\n');
                stdout.writeln(take + (lines.length > previewMax ? '\n... (truncated)' : ''));
              } else {
                stdout.writeln(diffTxt);
              }
            } catch (_) {}
          }
          if (hitl && !hitlAll) {
            try { await promptHitl('Apply edit to ' + p + '?'); } catch (_) { summary.add({'path': p, 'skipped': true, 'reason': 'user_aborted'}); continue; }
          }
          if (dry) { summary.add({'path': p, 'applied': false, 'dry_run': true}); continue; }
          try {
            final f = File(p);
            await f.parent.create(recursive: true);
            // write backup if requested
            if (backupDir.isNotEmpty && await f.exists()) {
              try {
                final rel = p.replaceAll('..', '__');
                final ts = DateTime.now().millisecondsSinceEpoch;
                final bpath = backupDir.endsWith('/') ? (backupDir + rel + '.$ts.bak') : (backupDir + '/' + rel + '.$ts.bak');
                await File(bpath).parent.create(recursive: true);
                await File(bpath).writeAsString(await f.readAsString());
              } catch (_) {}
            }
            await f.writeAsString(content);
            applied++;
            summary.add({'path': p, 'applied': true});
          } catch (e) {
            summary.add({'path': p, 'error': e.toString()});
          }
        }
        j({'ok': true, 'domain': 'sdk', 'action': 'apply-edits', 'trace_id': tid, 'considered': considered, 'applied': applied, 'dry_run': dry, 'summary': summary});
        return 0;
      }
    case 'apply-restore':
      {
        final filePath = (c['file']?.toString() ?? '').trim();
        String backupDir = (c['backup-dir']?.toString() ?? '').trim();
        if (backupDir.isEmpty) backupDir = '.cogo/backups';
        final listOnly = (c['list'] == true);
        final ts = (c['ts']?.toString() ?? '').trim();
        final latest = (c['latest'] == true);
        final dry = (c['dry-run'] == true);
        if (filePath.isEmpty) { j({'ok': false, 'error': 'file_required'}); return 2; }
        // backups are stored as backupDir/<sanitized_path>.<ts>.bak
        final sanitized = filePath.replaceAll('..', '__');
        final base = backupDir.endsWith('/') ? (backupDir + sanitized) : (backupDir + '/' + sanitized);
        final dir = Directory(backupDir);
        if (!await dir.exists()) { j({'ok': false, 'error': 'backup_dir_not_found', 'dir': backupDir}); return 2; }
        final pattern = RegExp(RegExp.escape(base) + r'\.([0-9]+)\.bak$');
        final candidates = <Map<String, dynamic>>[];
        await for (final ent in dir.list(recursive: true, followLinks: false)) {
          if (ent is File) {
            final p = ent.path;
            final m = pattern.firstMatch(p);
            if (m != null) {
              final tss = m.group(1) ?? '';
              final n = int.tryParse(tss) ?? 0;
              candidates.add({'ts': n, 'path': p});
            }
          }
        }
        candidates.sort((a,b)=> (b['ts'] as int).compareTo(a['ts'] as int));
        if (listOnly) { j({'ok': true, 'backups': candidates}); return 0; }
        String? restorePath;
        if (ts.isNotEmpty) {
          restorePath = candidates.firstWhere((e)=> (e['ts'].toString() == ts), orElse: ()=> const {'path': null})['path'] as String?;
        } else if (latest && candidates.isNotEmpty) {
          restorePath = candidates.first['path'] as String;
        }
        if (restorePath == null) { j({'ok': false, 'error': 'backup_not_found', 'file': filePath, 'backup_dir': backupDir}); return 2; }
        if (dry) { j({'ok': true, 'dry_run': true, 'restore_from': restorePath, 'to': filePath}); return 0; }
        try {
          final data = await File(restorePath).readAsString();
          await File(filePath).parent.create(recursive: true);
          await File(filePath).writeAsString(data);
          j({'ok': true, 'restored_from': restorePath, 'file': filePath});
          return 0;
        } catch (e) {
          j({'ok': false, 'error': 'restore_failed', 'message': e.toString()});
          return 2;
        }
      }
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
    case 'artifacts-upload':
    case 'artifacts-upload-batch':
    case 'artifacts-download':
      return await artifacts_cmd.handleArtifacts(http, c, _projectId(ar), ar);
    case 'artifacts-list':
      {
        final dir = (c['log-dir']?.toString() ?? '').trim();
        final pat = (c['pattern']?.toString() ?? '').trim();
        final asJson = (c['json'] == true);
        if (dir.isEmpty) { j({'ok': false, 'error': 'log_dir_required'}); return 2; }
        final d = Directory(dir);
        if (!await d.exists()) { j({'ok': false, 'error': 'log_dir_not_found', 'dir': dir}); return 2; }
        final files = <String>[];
        await for (final ent in d.list(recursive: true, followLinks: false)) {
          if (ent is File) {
            final p = ent.path;
            if (pat.isEmpty || p.contains(pat)) files.add(p);
          }
        }
        if (asJson) { j({'ok': true, 'files': files}); } else { stdout.writeln(files.join('\n')); }
        return 0;
      }
    case 'artifacts-rm':
      {
        final dir = (c['log-dir']?.toString() ?? '').trim();
        final pat = (c['pattern']?.toString() ?? '').trim();
        final dry = (c['dry-run'] == true);
        if (dir.isEmpty || pat.isEmpty) { j({'ok': false, 'error': 'args_required'}); return 2; }
        final d = Directory(dir);
        if (!await d.exists()) { j({'ok': false, 'error': 'log_dir_not_found', 'dir': dir}); return 2; }
        final affected = <String>[];
        await for (final ent in d.list(recursive: true, followLinks: false)) {
          if (ent is File && ent.path.contains(pat)) {
            affected.add(ent.path);
          }
        }
        if (!dry) {
          for (final p in affected) { try { await File(p).delete(); } catch (_) {} }
        }
        j({'ok': true, 'removed': dry ? 0 : affected.length, 'matched': affected.length, 'dry_run': dry, 'files': affected});
        return 0;
      }
    case 'json-set':
    case 'json-merge':
    case 'json-remove':
      return await json_cmd.handleJson(c);

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
      if (c.name == 'session-summary') { return await config_cmd.handleSessionSummary(c); }
      stdout.writeln('Unknown command');
      return 2;
  }
}

// moved to core/diff.dart and core/utils.dart
