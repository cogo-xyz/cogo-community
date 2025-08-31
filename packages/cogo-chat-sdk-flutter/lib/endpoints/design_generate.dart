import 'dart:async';
import 'dart:convert';
import '../utils/sse.dart';

class CogoDesignGenerateEndpoint {
  final String edgeBase;
  final String anonKey;
  const CogoDesignGenerateEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<void> stream(
    Map<String, dynamic> body,
    void Function(String, String) onEvent, {
    StreamController<void>? abort,
  }) async {
    final url = Uri.parse('${edgeBase.replaceAll(RegExp(r'/+$'), '')}/design-generate');
    await SseUtils.stream(url, _headers(), jsonEncode(body), onEvent, abort: abort);
  }
}
