import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUtils {
  static SupabaseClient createClient({required String supabaseUrl, required String anonKey}) {
    return SupabaseClient(supabaseUrl, anonKey);
  }
}

class TraceSubscriber {
  final SupabaseClient client;
  TraceSubscriber(this.client);

  Future<Stream<Map<String, dynamic>>> streamBroadcast(String traceId) async {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    final dynamic channel = client.channel('trace:$traceId');
    // Listen to any broadcast event; payload shape: { event, payload }
    channel.on('broadcast', { 'event': '*' }, (payload, [ref]) {
      try {
        if (payload is Map) {
          final event = payload['event']?.toString() ?? '';
          final data = payload['payload'];
          controller.add({ 'event': event, 'payload': data });
        }
      } catch (_) {}
    });
    await channel.subscribe();
    controller.onCancel = () async {
      try { await client.removeChannel(channel); } catch (_) {}
    };
    return controller.stream;
  }
}

