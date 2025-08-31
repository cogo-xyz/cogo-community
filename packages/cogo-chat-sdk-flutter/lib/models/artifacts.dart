class IngestResult {
  final bool ok;
  final String status; // 'pending' | 'ready'
  final String? bucket;
  final String? key;
  final String? signedUrl;

  IngestResult({
    required this.ok,
    required this.status,
    this.bucket,
    this.key,
    this.signedUrl,
  });

  factory IngestResult.fromJson(Map<String, dynamic> json) {
    return IngestResult(
      ok: (json['ok'] as bool?) ?? false,
      status: (json['status'] as String?) ?? 'pending',
      bucket: json['bucket'] as String?,
      key: json['key'] as String?,
      signedUrl: json['signedUrl'] as String?,
    );
  }
}
