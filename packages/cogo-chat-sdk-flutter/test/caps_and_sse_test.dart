import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:cogo_chat_sdk_flutter/cogo_chat_client.dart';

void main() {
  final edge = Platform.environment['SUPABASE_EDGE'] ??
      ((Platform.environment['SUPABASE_PROJECT_ID'] != null)
          ? 'https://${Platform.environment['SUPABASE_PROJECT_ID']}.functions.supabase.co/functions/v1'
          : null);
  final anon = Platform.environment['SUPABASE_ANON_KEY'];

  if (edge == null || anon == null) {
    print('[skipped] missing SUPABASE_EDGE/PROJECT_ID or SUPABASE_ANON_KEY');
    return;
  }

  group('caps & sse', () {
    final client = CogoChatClient(edgeBase: edge, anonKey: anon);

    test('capabilities info ok', () async {
      final caps = await client.capabilities.info();
      expect(caps.ok, true);
    });

    test('design-generate typed stream closes on done or abort-timer', () async {
      final abort = StreamController<void>();
      final timer = Timer(const Duration(seconds: 5), () { abort.add(null); });
      final events = <String>[];
      await client.designGenerate.stream({
        'prompt': 'Hello',
        'dev_flags': { 'dev_handoff_after_ms': 50 }
      }, (e, d) {
        events.add(e);
        print('[sse] event='+e+' data='+d);
        if (e == 'done' || e == 'error') abort.add(null);
      }, abort: abort);
      timer.cancel();
      await abort.close();
      expect(events.isNotEmpty, true);
    });
  });
}


