class EnvelopeV1 {
  final String? envelopeVersion;
  final String? traceId;

  EnvelopeV1({this.envelopeVersion, this.traceId});

  factory EnvelopeV1.fromJson(Map<String, dynamic> json) {
    return EnvelopeV1(
      envelopeVersion: json['envelope_version'] as String?,
      traceId: json['trace_id'] as String?,
    );
  }
}
