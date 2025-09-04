import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

void _j(Object o) => stdout.writeln(const JsonEncoder.withIndent('  ').convert(o));

Future<int> handleJsonValidate(ArgResults c, String? outJson) async {
  final rest = c.rest;
  if (rest.length < 2) {
    final err = {'ok': false, 'error': 'usage', 'message': 'json-validate <schemaId>@<version> <json_file>', 'need': ['schemaId@version', 'json_file']};
    _writeIfPath(outJson, jsonEncode(err));
    _j(err);
    return 2;
  }
  final idVer = rest[0];
  String jsonPath = rest[1];
  final dirOpt = (c['creatego-packages-dir']?.toString() ?? '').trim();
  final candidates = <String>[
    if (dirOpt.isNotEmpty) dirOpt,
    'external/cogo-client/creatego-packages',
    '../external/cogo-client/creatego-packages',
    '../../external/cogo-client/creatego-packages',
  ];
  String? pkgDir;
  for (final p in candidates) {
    final d = Directory(p);
    if (d.existsSync() && File(p + '/bin/json_validator.dart').existsSync()) { pkgDir = d.absolute.path; break; }
  }
  if (pkgDir == null) {
    final err = {'ok': false, 'error': 'creatego_packages_not_found', 'tried': candidates};
    _writeIfPath(outJson, jsonEncode(err));
    _j(err);
    return 2;
  }
  try {
    // Normalize to absolute path so child workingDirectory doesn't affect resolution
    final f = File(jsonPath);
    if (!f.isAbsolute) {
      jsonPath = f.absolute.path;
    } else {
      jsonPath = f.path;
    }
    final pr = await Process.run('dart', ['run', 'bin/json_validator.dart', idVer, jsonPath], workingDirectory: pkgDir);
    final stdoutStr = (pr.stdout is String) ? (pr.stdout as String) : utf8.decode(pr.stdout as List<int>);
    final stderrStr = (pr.stderr is String) ? (pr.stderr as String) : utf8.decode(pr.stderr as List<int>);
    final issues = <String>[];
    bool ok = false;
    for (final line in stdoutStr.split('\n')) {
      final l = line.trim();
      if (l.startsWith('OK:')) { ok = true; }
      if (l.startsWith('- ')) { issues.add(l.substring(2).trim()); }
    }
    final res = {
      'ok': ok && pr.exitCode == 0 && issues.isEmpty,
      'exit_code': pr.exitCode,
      'schema': idVer,
      'file': jsonPath,
      if (issues.isNotEmpty) 'issues': issues,
      if (stdoutStr.trim().isNotEmpty) 'stdout': stdoutStr.trim(),
      if (stderrStr.trim().isNotEmpty) 'stderr': stderrStr.trim(),
    };
    _writeIfPath(outJson, jsonEncode(res));
    _j(res);
    return res['ok'] == true ? 0 : 1;
  } catch (e, st) {
    final err = {'ok': false, 'error': 'spawn_failed', 'message': e.toString(), 'stack': st.toString()};
    _writeIfPath(outJson, jsonEncode(err));
    _j(err);
    return 2;
  }
}

void _writeIfPath(String? path, String content) {
  final p = (path ?? '').trim();
  if (p.isEmpty) return;
  try { File(p).writeAsStringSync(content); } catch (_) {}
}


