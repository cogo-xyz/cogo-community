import 'dart:async';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'sse.dart';
import 'supabase.dart';

@immutable
class TypedHandlers {
  final void Function(Map<String, dynamic> json)? meta;
  final void Function(Map<String, dynamic> json)? delta;
  final void Function(Map<String, dynamic> json)? done;
  final void Function(Map<String, dynamic> json)? error;
  final void Function(Map<String, dynamic> json)? queued;
  final void Function(Map<String, dynamic> json)? handoff;

  const TypedHandlers({
    this.meta,
    this.delta,
    this.done,
    this.error,
    this.queued,
    this.handoff,
  });
}

Future<void> streamTyped(
  Uri url,
  Map<String, String> headers,
  Object? body,
  TypedHandlers handlers, {
  StreamController<void>? abort,
  Duration timeout = const Duration(seconds: 30),
}) async {
  await SseUtils.stream(url, headers, body, (event, data) {
    Map<String, dynamic> json;
    try {
      json = data.isNotEmpty ? (jsonDecode(data) as Map<String, dynamic>) : <String, dynamic>{};
    } catch (_) {
      json = {'raw': data};
    }
    switch (event) {
      case 'meta': handlers.meta?.call(json); break;
      case 'delta': handlers.delta?.call(json); break;
      case 'done': handlers.done?.call(json); break;
      case 'error': handlers.error?.call(json); break;
      case 'queued': handlers.queued?.call(json); break;
      case 'handoff': handlers.handoff?.call(json); break;
      default: handlers.delta?.call(json); break;
    }
  }, abort: abort, timeout: timeout);
}

Future<void> streamOrRealtime({
  required Uri url,
  required Map<String, String> headers,
  required Object? body,
  required void Function(String event, Map<String, dynamic> json) onEvent,
  TraceSubscriber? traceSubscriber,
  StreamController<void>? abort,
  Duration timeout = const Duration(seconds: 30),
}) async {
  StreamSubscription<Map<String, dynamic>>? rtSub;
  bool rtStarted = false;
  final abortCtl = abort ?? StreamController<void>();

  Future<void> startRt(Map<String, dynamic> json) async {
    if (rtStarted || traceSubscriber == null) return;
    final traceId = (json['trace_id']?.toString() ?? json['traceId']?.toString() ?? '').trim();
    if (traceId.isEmpty) return;
    rtStarted = true;
    final stream = await traceSubscriber.streamBroadcast(traceId);
    rtSub = stream.listen((evt) {
      final event = evt['event']?.toString() ?? 'broadcast';
      final payload = (evt['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      onEvent(event, payload);
    });
  }

  try {
    await streamTyped(url, headers, body, TypedHandlers(
      meta: (j) => onEvent('meta', j),
      delta: (j) => onEvent('delta', j),
      done: (j) { onEvent('done', j); abortCtl.add(null); },
      error: (j) { onEvent('error', j); abortCtl.add(null); },
      queued: (j) { onEvent('queued', j); startRt(j); },
      handoff: (j) { onEvent('handoff', j); startRt(j); },
    ), abort: abortCtl, timeout: timeout);
  } finally {
    await rtSub?.cancel();
    if (abort == null) {
      await abortCtl.close();
    }
  }
}


