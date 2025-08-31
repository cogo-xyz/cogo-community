import 'dart:convert';
import '../utils/http.dart';

class CogoAttachmentsEndpoint {
  final String edgeBase;
  final String anonKey;

  const CogoAttachmentsEndpoint({required this.edgeBase, required this.anonKey});

  Map<String, String> _headers({String? idempotencyKey}) => {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty) 'idempotency-key': idempotencyKey,
      };

  Future<Map<String, dynamic>> presign({
    required String projectId,
    required String fileName,
    String? idempotencyKey,
  }) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/presign';
    final body = jsonEncode({ 'projectId': projectId, 'fileName': fileName });
    return await HttpUtils.fetchJson(url, method: 'POST', headers: _headers(idempotencyKey: idempotencyKey), body: body);
  }

  Future<Map<String, dynamic>> ingest({
    required String projectId,
    required String storageKey,
    String? traceId,
    String? sha256,
    int? size,
    String? idempotencyKey,
  }) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/ingest';
    final payload = <String, dynamic>{
      'projectId': projectId,
      'storage_key': storageKey,
      if (traceId != null) 'traceId': traceId,
      if (sha256 != null) 'sha256': sha256,
      if (size != null) 'size': size,
    };
    return await HttpUtils.fetchJson(url, method: 'POST', headers: _headers(idempotencyKey: idempotencyKey), body: jsonEncode(payload));
  }

  Future<Map<String, dynamic>> ingestResult({
    required String traceId,
  }) async {
    final base = edgeBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/figma-compat/uui/ingest/result?traceId=$traceId';
    return await HttpUtils.fetchJson(url, method: 'GET', headers: _headers());
  }
}
