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
  final supaUrl = Platform.environment['SUPABASE_URL'] ??
      ((Platform.environment['SUPABASE_PROJECT_ID'] != null)
          ? 'https://${Platform.environment['SUPABASE_PROJECT_ID']}.supabase.co'
          : null);

  if (edge == null || anon == null || supaUrl == null) {
    print('[skipped] missing env');
    return;
  }

  group('handoff/queued', () {
    test('streamOrRealtime switches on queued/handoff or abort-timer', () async {
      final supa = SupabaseUtils.createClient(supabaseUrl: supaUrl, anonKey: anon);
      final traceSub = TraceSubscriber(supa);
      final events = <String>[];
      final abort = StreamController<void>();
      final timer = Timer(const Duration(seconds: 8), () { abort.add(null); });
      final body = {
        'prompt': 'Hello',
        'dev_flags': { 'dev_queue_sim': true, 'dev_handoff_after_ms': 50 },
      };
      await streamOrRealtime(
        url: Uri.parse('$edge/design-generate'),
        headers: { 'Authorization': 'Bearer $anon', 'apikey': anon },
        body: body,
        onEvent: (e, j) { events.add(e); print('[or] event='+e+' json='+j.toString()); if (e == 'done' || e == 'error') abort.add(null); },
        traceSubscriber: traceSub,
        abort: abort,
      );
      timer.cancel();
      await abort.close();
      expect(events.any((e) => e == 'queued' || e == 'handoff' || e == 'done' || e == 'error'), true);
    });
  });
}


