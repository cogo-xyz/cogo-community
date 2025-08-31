import 'dart:convert';
import 'dart:io';

class JsonOps {
  static dynamic deepMerge(dynamic base, dynamic patch) {
    if (base is Map && patch is Map) {
      final out = Map<String, dynamic>.from(base);
      patch.forEach((k, v) {
        out[k] = deepMerge(out[k], v);
      });
      return out;
    }
    if (base is List && patch is List) {
      return [...base, ...patch];
    }
    return patch; // overwrite
  }

  static List<String> _splitPointer(String pointer) {
    var p = pointer.trim();
    if (p.isEmpty || p == '/') return <String>[];
    if (p.startsWith('/')) p = p.substring(1);
    return p.split('/').map((s) => s.replaceAll('~1', '/').replaceAll('~0', '~')).toList();
  }

  static dynamic getAtPointer(dynamic json, String pointer) {
    final parts = _splitPointer(pointer);
    dynamic cur = json;
    for (final key in parts) {
      if (cur is Map) {
        cur = cur[key];
      } else if (cur is List) {
        final idx = int.tryParse(key) ?? -1;
        if (idx < 0 || idx >= cur.length) return null;
        cur = cur[idx];
      } else {
        return null;
      }
    }
    return cur;
  }

  static dynamic setAtPointer(dynamic json, String pointer, dynamic value) {
    final parts = _splitPointer(pointer);
    if (parts.isEmpty) return value;
    dynamic cur = json;
    for (int i = 0; i < parts.length; i++) {
      final key = parts[i];
      final last = i == parts.length - 1;
      if (cur is Map) {
        if (last) {
          cur[key] = value;
        } else {
          cur[key] = cur[key] ?? <String, dynamic>{};
          if (cur[key] is! Map && cur[key] is! List) cur[key] = <String, dynamic>{};
          cur = cur[key];
        }
      } else if (cur is List) {
        final idx = int.tryParse(key) ?? cur.length;
        while (cur.length <= idx) { cur.add(null); }
        if (last) {
          cur[idx] = value;
        } else {
          cur[idx] = cur[idx] ?? <String, dynamic>{};
          cur = cur[idx];
        }
      } else {
        throw Exception('Invalid path segment at $key');
      }
    }
    return json;
  }

  static dynamic removeAtPointer(dynamic json, String pointer) {
    final parts = _splitPointer(pointer);
    if (parts.isEmpty) return null;
    dynamic cur = json;
    for (int i = 0; i < parts.length - 1; i++) {
      final key = parts[i];
      if (cur is Map) cur = cur[key];
      else if (cur is List) cur = cur[int.parse(key)];
      else return json;
    }
    final lastKey = parts.last;
    if (cur is Map) { cur.remove(lastKey); }
    else if (cur is List) {
      final idx = int.tryParse(lastKey);
      if (idx != null && idx >= 0 && idx < cur.length) { cur.removeAt(idx); }
    }
    return json;
  }

  static Future<Map<String, dynamic>> readJsonFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return <String, dynamic>{};
    final txt = await file.readAsString();
    return (jsonDecode(txt) as Map).cast<String, dynamic>();
  }

  static Future<void> writeJsonFile(String filePath, Map<String, dynamic> data, {String? backupDir}) async {
    final file = File(filePath);
    if (await file.exists() && backupDir != null && backupDir.isNotEmpty) {
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = '$backupDir/$ts/$filePath';
      final bFile = File(backupPath);
      await bFile.parent.create(recursive: true);
      await bFile.writeAsString(await file.readAsString());
    }
    await file.parent.create(recursive: true);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }
}


