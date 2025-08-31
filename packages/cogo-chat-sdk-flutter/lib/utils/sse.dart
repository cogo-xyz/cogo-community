import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef SseHandler = void Function(String event, String data);

class SseUtils {
  static Future<void> stream(
    Uri url,
    Map<String, String> headers,
    Object? body,
    SseHandler onEvent, {
    Duration timeout = const Duration(seconds: 30),
    StreamController<void>? abort,
  }) async {
    final req = http.Request('POST', url);
    req.headers.addAll({'accept': 'text/event-stream', ...headers});
    if (body != null) {
      req.headers['content-type'] = 'application/json';
      req.body = body is String ? body : jsonEncode(body);
    }
    final client = http.Client();
    http.StreamedResponse resp;
    try {
      resp = await client.send(req).timeout(timeout);
    } catch (e) {
      client.close();
      rethrow;
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      client.close();
      throw Exception('SSE error: ${resp.statusCode}');
    }
    final completer = Completer<void>();
    final sub = resp.stream.listen((chunk) {
      final text = utf8.decode(chunk);
      for (final frame in text.split('\n\n')) {
        if (frame.trim().isEmpty) continue;
        String event = 'message';
        String data = '';
        for (final line in frame.split('\n')) {
          if (line.startsWith('event: ')) event = line.substring(7).trim();
          if (line.startsWith('data: ')) data += line.substring(6);
        }
        onEvent(event, data);
      }
    }, onDone: () { if (!completer.isCompleted) completer.complete(); }, onError: (_) { if (!completer.isCompleted) completer.complete(); });
    final abortSub = abort?.stream.listen((_) {
      sub.cancel();
      client.close();
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    await abortSub?.cancel();
    try { client.close(); } catch (_) {}
  }
}
