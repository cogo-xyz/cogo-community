import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

void _j(Object o) => stdout.writeln(const JsonEncoder.withIndent('  ').convert(o));

Future<int> handleFilesChanged(ArgResults c) async {
  try {
    final since = (c['since']?.toString() ?? '').trim();
    final base = (c['base']?.toString() ?? '').trim();
    final staged = (c['staged'] == true);
    final nameOnly = (c['name-only'] == true);
    final stat = (c['stat'] == true);
    final asJson = (c['json'] == true);

    List<String> args = [];
    if (since.isNotEmpty || base.isNotEmpty) {
      final lhs = base.isNotEmpty ? base : (since.isNotEmpty ? since : 'HEAD');
      args = ['diff', lhs];
      if (nameOnly) args.add('--name-only');
      if ((c['name-status'] == true)) args.add('--name-status');
      if (stat) args.add('--shortstat');
    } else {
      args = ['status', '--porcelain'];
    }
    if (staged) {
      if (args.isNotEmpty && args.first == 'diff') args.add('--cached');
    }
    final pr = await Process.run('git', args);
    final out = (pr.stdout?.toString() ?? '').trim();
    if (!asJson) { stdout.writeln(out); return 0; }

    if (args.first == 'status') {
      final lines = out.isEmpty ? <String>[] : out.split('\n');
      final changes = lines.map((l) {
        final s = l.trimRight();
        final code = s.length >= 2 ? s.substring(0, 2).trim() : s;
        final path = s.length > 3 ? s.substring(3).trim() : '';
        return {'code': code, 'path': path};
      }).toList();
      _j({'ok': true, 'schema': 'files-changed@v1', 'mode': 'status', 'changes': changes});
    } else {
      if (nameOnly) {
        final files = out.isEmpty ? <String>[] : out.split('\n').where((x)=> x.trim().isNotEmpty).toList();
        _j({'ok': true, 'schema': 'files-changed@v1', 'mode': 'diff', 'name_only': true, 'files': files});
      } else if ((c['name-status'] == true)) {
        final lines = out.isEmpty ? <String>[] : out.split('\n').where((x)=> x.trim().isNotEmpty).toList();
        final entries = lines.map((l) {
          final parts = l.split('\t');
          final status = parts.isNotEmpty ? parts.first.trim() : '';
          String from = '';
          String to = '';
          if (parts.length >= 2) {
            final rest = parts.sublist(1).join('\t');
            if (rest.contains(' -> ')) {
              final segs = rest.split(' -> ');
              from = segs.first.trim();
              to = segs.last.trim();
            } else {
              to = rest.trim();
            }
          }
          return {'status': status, if (from.isNotEmpty) 'from': from, 'path': to.isNotEmpty ? to : from};
        }).toList();
        _j({'ok': true, 'schema': 'files-changed@v1', 'mode': 'diff', 'name_status': true, 'entries': entries});
      } else if (stat) {
        final reFiles = RegExp(r'([0-9]+) files? changed');
        final reIns = RegExp(r'([0-9]+) insertions?\(\+\)');
        final reDel = RegExp(r'([0-9]+) deletions?\(-\)');
        int filesChanged = int.tryParse(reFiles.firstMatch(out)?.group(1) ?? '0') ?? 0;
        int insertions = int.tryParse(reIns.firstMatch(out)?.group(1) ?? '0') ?? 0;
        int deletions = int.tryParse(reDel.firstMatch(out)?.group(1) ?? '0') ?? 0;
        _j({'ok': true, 'schema': 'files-changed@v1', 'mode': 'diff', 'shortstat': {'files_changed': filesChanged, 'insertions': insertions, 'deletions': deletions}, 'raw': out});
      } else {
        _j({'ok': true, 'schema': 'files-changed@v1', 'mode': 'diff', 'raw': out});
      }
    }
    return 0;
  } catch (e) {
    _j({'ok': false, 'error': 'git_failed', 'message': e.toString()});
    return 2;
  }
}


