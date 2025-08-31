import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseArtifactsUtils {
  static Future<Map<String, dynamic>> head(SupabaseClient sb, String bucket, String key) async {
    try {
      final signedUrl = await sb.storage.from(bucket).createSignedUrl(key, 60);
      final res = await http.head(Uri.parse(signedUrl));
      final ct = res.headers['content-type'];
      final lenStr = res.headers['content-length'];
      final size = lenStr != null ? int.tryParse(lenStr) : null;
      return { 'contentType': ct, 'size': size };
    } catch (_) {
      // Fallback: download bytes and infer size
      final bytes = await sb.storage.from(bucket).download(key);
      return { 'contentType': null, 'size': bytes.length };
    }
  }

  static Future<Map<String, dynamic>> downloadJson(SupabaseClient sb, String bucket, String key) async {
    final bytes = await sb.storage.from(bucket).download(key);
    final text = utf8.decode(bytes);
    return jsonDecode(text) as Map<String, dynamic>;
  }
}


