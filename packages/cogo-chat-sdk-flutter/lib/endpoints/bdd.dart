import 'dart:convert';
import '../utils/http.dart';

class CogoBddEndpoint {
  final String edgeBase;
  final String anonKey;
  const CogoBddEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<Map<String, dynamic>> generate(Map<String, dynamic> body) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/bdd/generate';
    return await HttpUtils.fetchJson(url, method: 'POST', headers: _headers(), body: jsonEncode(body));
  }

  Future<Map<String, dynamic>> refine(Map<String, dynamic> body) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/bdd/refine';
    return await HttpUtils.fetchJson(url, method: 'POST', headers: _headers(), body: jsonEncode(body));
  }
}
