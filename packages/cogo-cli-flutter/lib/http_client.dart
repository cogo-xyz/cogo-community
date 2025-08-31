import 'dart:io';
import 'package:http/http.dart' as http;

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


