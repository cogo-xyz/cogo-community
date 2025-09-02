import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:cogo_cli_flutter/http_client.dart';
import 'package:cogo_cli_flutter/core/utils.dart' as core;

void _j(Object o) => stdout.writeln(const JsonEncoder.withIndent('  ').convert(o));

Future<int> handleTrace(EdgeHttp http, ArgResults c, String baseUrl) async {
  final sub = (c).command;
  if (sub == null) { stdout.writeln('Usage: trace <status|logs|open>'); return 2; }
  switch (sub.name) {
    case 'status':
      {
        String id = (sub['trace-id']?.toString() ?? '').trim();
        if (id.isEmpty && sub.rest.isNotEmpty) { id = sub.rest.first.toString(); }
        if (id.isEmpty) { _j({'ok': false, 'error': 'trace_id_required'}); return 2; }
        final watch = (sub['watch'] == true);
        final cfg = loadRunnerConfig();
        final interval = int.tryParse((sub['interval-seconds']?.toString() ?? '2')) ?? 2;
        final timeout = int.tryParse((sub['timeout-seconds']?.toString() ?? (cfg.defaultTimeoutSec.toString()))) ?? cfg.defaultTimeoutSec;
        if (!watch) {
          final r = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(id));
          _j({'ok': r.statusCode == 200, 'result': core.tryJson(r.body)});
          return 0;
        }
        final started = DateTime.now();
        Map last = {};
        while (true) {
          final rr = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(id));
          final ro = core.tryJson(rr.body) as Map;
          last = ro;
          final st = (ro['status']?.toString() ?? '');
          if ((sub['show-progress'] == true)) {
            int events = 0; String? lastAt;
            try {
              final evs = (ro['events'] as List?);
              events = evs?.length ?? 0;
              if (events > 0) {
                final lastEv = evs!.last as Map?;
                lastAt = lastEv?['ts']?.toString();
              }
            } catch (_) {}
            stdout.writeln(const JsonEncoder.withIndent('  ').convert({'tick': DateTime.now().toIso8601String(), 'status': st, 'events_count': events, if (lastAt != null) 'last_event_at': lastAt}));
          } else {
            stdout.writeln(const JsonEncoder.withIndent('  ').convert({'tick': DateTime.now().toIso8601String(), 'status': st}));
          }
          if (st == 'ready' || st == 'failed') { _j({'ok': true, 'result': ro}); return 0; }
          if (DateTime.now().difference(started).inSeconds >= timeout) { _j({'ok': true, 'timeout': timeout, 'last': last}); return 0; }
          await Future<void>.delayed(Duration(seconds: interval));
        }
      }
    case 'logs':
      {
        String id = (sub['trace-id']?.toString() ?? '').trim();
        if (id.isEmpty && sub.rest.isNotEmpty) { id = sub.rest.first.toString(); }
        if (id.isEmpty) { _j({'ok': false, 'error': 'trace_id_required'}); return 2; }
        final watch = (sub['watch'] == true);
        final interval = int.tryParse((sub['interval-seconds']?.toString() ?? '3')) ?? 3;
        final maxErrors = int.tryParse((sub['max-errors']?.toString() ?? '5')) ?? 5;
        final backoffMs = int.tryParse((sub['retry-backoff-ms']?.toString() ?? '500')) ?? 500;
        final showProg = (sub['show-progress'] == true);
        if (!watch) {
          try {
            final r = await http.get('/api/metrics/trace/' + Uri.encodeComponent(id));
            if (r.statusCode >= 200 && r.statusCode < 300) { _j({'ok': true, 'source': 'metrics', 'result': core.tryJson(r.body)}); return 0; }
          } catch (_) {}
          final rs = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(id));
          final obj = core.tryJson(rs.body) as Map;
          _j({'ok': rs.statusCode == 200, 'source': 'status', 'events': obj['events'] ?? [], 'result': obj});
          return 0;
        }
        int errCount = 0;
        final started = DateTime.now();
        int tick = 0;
        while (true) {
          try {
            final r = await http.get('/api/metrics/trace/' + Uri.encodeComponent(id));
            if (r.statusCode >= 200 && r.statusCode < 300) {
              final obj = core.tryJson(r.body) as Map;
              if (showProg) {
                tick++;
                final elapsed = DateTime.now().difference(started).inSeconds;
                int events = 0; String? lastAt;
                try {
                  final evs = (obj['events'] as List?);
                  events = evs?.length ?? 0;
                  if (events > 0) { final lastEv = evs!.last as Map?; lastAt = lastEv?['ts']?.toString(); }
                } catch (_) {}
                final spinner = ['|','/','-','\\'][tick % 4];
                stdout.writeln(const JsonEncoder.withIndent('  ').convert({'tick': spinner, 't_sec': elapsed, 'source': 'metrics', 'events_count': events, if (lastAt != null) 'last_event_at': lastAt}));
              } else {
                stdout.writeln(const JsonEncoder.withIndent('  ').convert({'source': 'metrics', 'result': obj}));
              }
            } else {
              final rs = await http.get('/trace-status?trace_id=' + Uri.encodeComponent(id));
              final obj = core.tryJson(rs.body) as Map;
              if (showProg) {
                tick++;
                final elapsed = DateTime.now().difference(started).inSeconds;
                int events = 0; String? lastAt;
                try {
                  final evs = (obj['events'] as List?);
                  events = evs?.length ?? 0;
                  if (events > 0) { final lastEv = evs!.last as Map?; lastAt = lastEv?['ts']?.toString(); }
                } catch (_) {}
                final spinner = ['|','/','-','\\'][tick % 4];
                stdout.writeln(const JsonEncoder.withIndent('  ').convert({'tick': spinner, 't_sec': elapsed, 'source': 'status', 'events_count': events, if (lastAt != null) 'last_event_at': lastAt}));
              } else {
                stdout.writeln(const JsonEncoder.withIndent('  ').convert({'source': 'status', 'events': obj['events'] ?? [], 'result': obj}));
              }
            }
            errCount = 0;
          } catch (e) {
            errCount++;
            try { stdout.writeln(const JsonEncoder.withIndent('  ').convert({'ok': false, 'error': 'logs_watch_failed', 'message': e.toString(), 'errors': errCount})); } catch (_) {}
            if (errCount >= maxErrors) { _j({'ok': false, 'error': 'logs_watch_gave_up', 'errors': errCount}); return 2; }
            await Future<void>.delayed(Duration(milliseconds: backoffMs * errCount));
          }
          await Future<void>.delayed(Duration(seconds: interval));
        }
      }
    case 'open':
      {
        String id = (sub['trace-id']?.toString() ?? '').trim();
        if (id.isEmpty && sub.rest.isNotEmpty) { id = sub.rest.first.toString(); }
        if (id.isEmpty) { _j({'ok': false, 'error': 'trace_id_required'}); return 2; }
        final override = (sub['url']?.toString() ?? '').trim();
        final url = override.isNotEmpty ? override : (baseUrl.replaceAll(RegExp(r"/+$$"), '') + '/api/metrics/trace/' + Uri.encodeComponent(id));
        final browserOpt = (sub['browser']?.toString() ?? '').trim();
        final envBrowser = (Platform.environment['BROWSER'] ?? '').trim();
        try {
          if (browserOpt.isNotEmpty) {
            await Process.run(browserOpt, [url]);
          } else if (envBrowser.isNotEmpty) {
            await Process.run(envBrowser, [url]);
          } else if (Platform.isMacOS) {
            await Process.run('open', [url]);
          } else if (Platform.isLinux) {
            try {
              final which = await Process.run('which', ['wslview']);
              if ((which.stdout.toString()).trim().isNotEmpty) {
                await Process.run('wslview', [url]);
              } else {
                await Process.run('xdg-open', [url]);
              }
            } catch (_) {
              await Process.run('xdg-open', [url]);
            }
          } else if (Platform.isWindows) {
            await Process.run('cmd', ['/c', 'start', url]);
          }
          _j({'ok': true, 'opened': url});
        } catch (e) {
          _j({'ok': false, 'url': url, 'error': e.toString()});
          stdout.writeln(url);
        }
        return 0;
      }
  }
  return 2;
}


