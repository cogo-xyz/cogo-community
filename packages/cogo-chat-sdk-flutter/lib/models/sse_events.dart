class SseFrame {
  final String event;
  final String data;
  SseFrame({required this.event, required this.data});
}

class QueuedEvent {
  final String? reason;
  QueuedEvent({this.reason});
  factory QueuedEvent.fromJson(Map<String, dynamic> json) => QueuedEvent(reason: json['reason']?.toString());
}

class HandoffEvent {
  final String? channel; // e.g., realtime
  final String? reason;
  HandoffEvent({this.channel, this.reason});
  factory HandoffEvent.fromJson(Map<String, dynamic> json) => HandoffEvent(
        channel: json['channel']?.toString(),
        reason: json['reason']?.toString(),
      );
}
