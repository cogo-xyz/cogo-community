import '../utils/http.dart';

class CogoIntentEndpoint {
  final String edgeBase;
  final String anonKey;
  const CogoIntentEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<Map<String, dynamic>> info() async {
    final url = '${edgeBase.replaceAll(RegExp(r'/+$'), '')}/intent-resolve/info';
    return await HttpUtils.fetchJson(url, headers: _headers());
  }

  Future<Map<String, dynamic>> resolve(String text) async {
    final url = '${edgeBase.replaceAll(RegExp(r'/+$'), '')}/intent-resolve';
    return await HttpUtils.fetchJson(url, method: 'POST', headers: _headers(), body: { 'text': text });
  }
}


