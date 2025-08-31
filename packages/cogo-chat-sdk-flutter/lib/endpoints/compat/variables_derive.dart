import 'dart:convert';
import '../../utils/http.dart';

class CogoVariablesDeriveEndpoint {
  final String edgeBase;
  final String anonKey;

  const CogoVariablesDeriveEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<Map<String, dynamic>> derive({
    required Map<String, dynamic> body,
  }) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/variables/derive';
    return await HttpUtils.fetchJson(
      url,
      method: 'POST',
      headers: _headers(),
      body: jsonEncode(body),
    );
  }
}
