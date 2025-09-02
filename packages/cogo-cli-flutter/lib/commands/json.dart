import 'dart:convert';
import 'package:args/args.dart';
import 'package:cogo_cli_flutter/json_ops.dart';

Future<int> handleJson(ArgResults c) async {
  switch (c.name) {
    case 'json-set':
      {
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final valStr = (c['value']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing'}); }
        dynamic value;
        try { value = jsonDecode(valStr); } catch (_) { value = valStr; }
        final data = await JsonOps.readJsonFile(path);
        final updated = JsonOps.setAtPointer(data, ptr, value) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        return _emit({'ok': true, 'domain': 'sdk', 'action': 'json-set', 'file': path, 'pointer': ptr});
      }
    case 'json-merge':
      {
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final valStr = (c['value']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing'}); }
        dynamic patch;
        try { patch = jsonDecode(valStr); } catch (_) { patch = valStr; }
        final data = await JsonOps.readJsonFile(path);
        final base = JsonOps.getAtPointer(data, ptr);
        final merged = JsonOps.deepMerge(base, patch);
        final updated = JsonOps.setAtPointer(data, ptr, merged) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        return _emit({'ok': true, 'domain': 'sdk', 'action': 'json-merge', 'file': path, 'pointer': ptr});
      }
    case 'json-remove':
      {
        final path = (c['file']?.toString() ?? '').trim();
        final ptr = (c['pointer']?.toString() ?? '').trim();
        final backup = (c['backup-dir']?.toString() ?? '').trim();
        if (path.isEmpty || ptr.isEmpty) { return _emit({'ok': false, 'error': 'args_missing'}); }
        final data = await JsonOps.readJsonFile(path);
        final updated = JsonOps.removeAtPointer(data, ptr) as Map<String, dynamic>;
        await JsonOps.writeJsonFile(path, updated, backupDir: backup.isEmpty ? null : backup);
        return _emit({'ok': true, 'domain': 'sdk', 'action': 'json-remove', 'file': path, 'pointer': ptr});
      }
  }
  return _emit({'ok': false, 'error': 'unknown_json_command'});
}

int _emit(Map obj) { print(const JsonEncoder.withIndent('  ').convert(obj)); return (obj['ok'] == true) ? 0 : 2; }


