class Capabilities {
  final bool ok;
  final String? envelopeVersion;
  final List<String> sseEvents;
  final Map<String, dynamic>? devFlagsSummary;
  final bool? editorContextSupport;

  Capabilities({
    required this.ok,
    this.envelopeVersion,
    required this.sseEvents,
    this.devFlagsSummary,
    this.editorContextSupport,
  });

  factory Capabilities.fromJson(Map<String, dynamic> json) {
    return Capabilities(
      ok: (json['ok'] as bool?) ?? true,
      envelopeVersion: json['envelope_version'] as String?,
      sseEvents: (json['sse_events'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      devFlagsSummary: json['dev_flags_summary'] as Map<String, dynamic>?,
      editorContextSupport: json['editor_context_support'] as bool?,
    );
  }
}
