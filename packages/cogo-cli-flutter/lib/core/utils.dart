import 'dart:convert';
import 'dart:io';

Object tryJson(String s) {
  try {
    return jsonDecode(s);
  } catch (_) {
    return {'text': s};
  }
}

void writeIfPath(String? path, String content) {
  final p = (path ?? '').trim();
  if (p.isEmpty) return;
  try {
    File(p).writeAsStringSync(content);
  } catch (_) {}
}

String contentTypeFor(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.json')) return 'application/json';
  if (lower.endsWith('.txt') || lower.endsWith('.log')) return 'text/plain';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.zip')) return 'application/zip';
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.svg')) return 'image/svg+xml';
  if (lower.endsWith('.md')) return 'text/markdown';
  if (lower.endsWith('.html') || lower.endsWith('.htm')) return 'text/html';
  if (lower.endsWith('.js')) return 'application/javascript';
  if (lower.endsWith('.css')) return 'text/css';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.mp3')) return 'audio/mpeg';
  if (lower.endsWith('.ico')) return 'image/x-icon';
  return 'application/octet-stream';
}

bool looksBinaryPath(String path) {
  final lower = path.toLowerCase();
  const binExt = [
    '.png','.jpg','.jpeg','.gif','.webp','.ico','.pdf','.zip','.tar','.gz','.mp4','.mp3','.mov','.exe','.dll'
  ];
  for (final e in binExt) { if (lower.endsWith(e)) return true; }
  return false;
}

int countSubstring(String haystack, String needle) {
  if (needle.isEmpty) return 0;
  int count = 0;
  int index = 0;
  while (true) {
    final i = haystack.indexOf(needle, index);
    if (i < 0) break;
    count++;
    index = i + needle.length;
  }
  return count;
}


