import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpUtils {
  static Future<Map<String, dynamic>> fetchJson(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 20),
    int retries = 2,
  }) async {
    Exception? last;
    for (int i = 0; i <= retries; i++) {
      try {
        final reqHeaders = {
          'content-type': 'application/json',
          ...?headers,
        };
        http.Response resp;
        if (method == 'GET') {
          resp = await http.get(Uri.parse(url), headers: reqHeaders).timeout(timeout);
        } else if (method == 'POST') {
          resp = await http
              .post(Uri.parse(url), headers: reqHeaders, body: body is String ? body : jsonEncode(body))
              .timeout(timeout);
        } else {
          final request = http.Request(method, Uri.parse(url));
          request.headers.addAll(reqHeaders);
          if (body != null) {
            request.body = body is String ? body : jsonEncode(body);
          }
          final client = http.Client();
          try {
            final streamed = await client.send(request).timeout(timeout);
            resp = await http.Response.fromStream(streamed);
          } finally {
            client.close();
          }
        }
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      } catch (e) {
        last = e is Exception ? e : Exception(e.toString());
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
      }
    }
    throw last ?? Exception('Unknown HTTP error');
  }
}
