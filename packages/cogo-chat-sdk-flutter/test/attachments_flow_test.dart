import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:cogo_chat_sdk_flutter/cogo_chat_client.dart';

void main() {
  final edge = Platform.environment['SUPABASE_EDGE'] ??
      ((Platform.environment['SUPABASE_PROJECT_ID'] != null)
          ? 'https://${Platform.environment['SUPABASE_PROJECT_ID']}.functions.supabase.co/functions/v1'
          : null);
  final anon = Platform.environment['SUPABASE_ANON_KEY'];
  final supaUrl = Platform.environment['SUPABASE_URL'] ??
      ((Platform.environment['SUPABASE_PROJECT_ID'] != null)
          ? 'https://${Platform.environment['SUPABASE_PROJECT_ID']}.supabase.co'
          : null);

  if (edge == null || anon == null || supaUrl == null) {
    print('[skipped] missing env');
    return;
  }

  group('attachments flow', () {
    test('presign → ingest → result', () async {
      final client = CogoChatClient(edgeBase: edge, anonKey: anon, supabaseUrl: supaUrl);
      final projectId = '00000000-0000-4000-8000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(13, '0').substring(0, 12)}';
      final pre = await client.attachments.presign(projectId: projectId, fileName: 'uui.json');
      print('[attachments] presign: '+ jsonEncode(pre));
      final key = pre['key']?.toString();
      expect(key?.isNotEmpty, true);

      // If signedUrl is provided, PUT directly; otherwise skip upload (server may ignore)
      if (pre['signedUrl'] is String) {
        final uri = Uri.parse(pre['signedUrl']);
        final req = await HttpClient().openUrl('PUT', uri);
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        req.add(utf8.encode(jsonEncode({'hello': 'world'})));
        final resp = await req.close();
        print('[attachments] PUT status: '+resp.statusCode.toString());
        expect(resp.statusCode, anyOf([200, 201]));
      }

      final ins = await client.attachments.ingest(projectId: projectId, storageKey: key!);
      print('[attachments] ingest: '+ jsonEncode(ins));
      final traceId = ins['trace_id']?.toString();
      expect(traceId?.isNotEmpty, true);

      // Poll result a few times (gated)
      Map<String, dynamic> result = {};
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(seconds: 1));
        result = await client.attachments.ingestResult(traceId: traceId!);
        print('[attachments] poll[$i]: '+ jsonEncode(result));
        if (result['status'] == 'ready') break;
      }
      expect(result['ok'], true);
      expect(result['status'], anyOf(['ready', 'pending']));
    });
  });
}


