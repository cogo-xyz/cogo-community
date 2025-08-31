import 'dart:convert';
import '../../utils/http.dart';

class CogoSymbolsMapEndpoint {
  final String edgeBase;
  final String anonKey;

  const CogoSymbolsMapEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<Map<String, dynamic>> map({
    required Map<String, dynamic> body,
  }) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/symbols/map';
    return await HttpUtils.fetchJson(
      url,
      method: 'POST',
      headers: _headers(),
      body: jsonEncode(body),
    );
  }
}
