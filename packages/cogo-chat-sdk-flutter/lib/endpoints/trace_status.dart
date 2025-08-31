import '../utils/http.dart';

class CogoTraceStatusEndpoint {
  final String edgeBase;
  final String anonKey;
  const CogoTraceStatusEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      };

  Future<Map<String, dynamic>> getStatus(String traceId) async {
    final url = '${edgeBase.replaceAll(RegExp(r'/+$'), '')}/trace-status?trace_id=$traceId';
    return await HttpUtils.fetchJson(url, headers: _headers());
  }
}


