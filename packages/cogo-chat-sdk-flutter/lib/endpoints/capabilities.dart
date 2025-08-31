import '../models/capabilities.dart';
import '../utils/http.dart';

class CogoCapabilitiesEndpoint {
  final String edgeBase;
  final String anonKey;

  const CogoCapabilitiesEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<Capabilities> info({bool includeFallback = false}) async {
    final path = includeFallback ? '/intent-resolve/info?include_fallback=1' : '/intent-resolve/info';
    final url = '${edgeBase.replaceAll(RegExp(r'/+$'), '')}$path';
    final json = await HttpUtils.fetchJson(url, headers: _headers());
    return Capabilities.fromJson(json);
  }
}
