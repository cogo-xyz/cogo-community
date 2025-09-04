import 'dart:convert';
import 'dart:io';

import 'package:cogo_cli_flutter/http_client.dart';

/// Flutter-style local batch: generate JSON → validate schema (simple) → show diff (via CLI)
/// DB upsert is intentionally excluded.
Future<void> main() async {
  final outDir = Directory('packages/cogo-cli-flutter/examples/out');
  await outDir.create(recursive: true);
  final modelPath = 'packages/cogo-cli-flutter/examples/out/model.json';

  // 1) Apply small JSON via dispatcher (no server needed)
  final model = {
    'title': 'Report',
    'version': 2,
    'items': [
      {'id': 1, 'name': 'alpha'},
      {'id': 2, 'name': 'beta'}
    ]
  };
  final actions = [
    {
      'type': 'apply_edits',
      'edits': [
        {
          'path': modelPath,
          'content': const JsonEncoder.withIndent('  ').convert(model)
        }
      ]
    }
  ];
  final summary1 = await dispatchNextActions(
    actions,
    hitl: false,
    auto: true,
    logDir: '.cogo/session',
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert({'step': 'apply_edits', 'summary': summary1}));

  // 2) Simple schema validation (Dart-side): require title:String, version:int >= 1
  final parsed = jsonDecode(await File(modelPath).readAsString()) as Map;
  final errors = <String>[];
  if (parsed['title'] is! String || (parsed['title'] as String).trim().isEmpty) {
    errors.add('title must be a non-empty string');
  }
  if (parsed['version'] is! int || (parsed['version'] as int) < 1) {
    errors.add('version must be integer >= 1');
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert({'step': 'schema_validate', 'ok': errors.isEmpty, if (errors.isNotEmpty) 'errors': errors}));
  if (errors.isNotEmpty) exit(2);

  // 3) Show diff via CLI files-changed (status-based)
  final actions2 = [
    {
      'type': 'cli',
      'cmd': 'dart',
      'args': [
        'run',
        'packages/cogo-cli-flutter/bin/cogo_cli_flutter.dart',
        'files-changed',
        '--json'
      ]
    }
  ];
  final summary2 = await dispatchNextActions(
    actions2,
    hitl: false,
    auto: true,
    logDir: '.cogo/session',
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert({'step': 'diff', 'summary': summary2}));

  stdout.writeln('DONE');
}


