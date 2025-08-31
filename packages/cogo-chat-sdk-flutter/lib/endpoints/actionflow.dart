import 'dart:convert';
import '../utils/http.dart';

class CogoActionflowEndpoint {
  final String edgeBase;
  final String anonKey;
  const CogoActionflowEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<Map<String, dynamic>> refine(Map<String, dynamic> body) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/actionflow/refine';
    return await HttpUtils.fetchJson(url, method: 'POST', headers: _headers(), body: jsonEncode(body));
  }
}
