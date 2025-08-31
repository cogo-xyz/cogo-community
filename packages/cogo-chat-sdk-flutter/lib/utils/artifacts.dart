import 'dart:convert';
import 'package:http/http.dart' as http;

class ArtifactsUtils {
  static Future<int> headStatus(String url, {Duration timeout = const Duration(seconds: 10)}) async {
    final req = http.Request('HEAD', Uri.parse(url));
    final resp = await http.Client().send(req).then(http.Response.fromStream).timeout(timeout);
    return resp.statusCode;
  }

  static Future<Map<String, dynamic>> downloadJson(String url, {Duration timeout = const Duration(seconds: 30)}) async {
    final resp = await http.get(Uri.parse(url)).timeout(timeout);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Download error ${resp.statusCode}');
  }
}
