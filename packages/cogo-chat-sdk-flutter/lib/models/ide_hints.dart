class IdeHintToast {
  final String message;
  final String? lang;

  IdeHintToast({required this.message, this.lang});

  factory IdeHintToast.fromJson(Map<String, dynamic> json) => IdeHintToast(
        message: json['message']?.toString() ?? '',
        lang: json['lang']?.toString(),
      );
}

class IdeHints {
  final String? toast;
  final String? toastKo;
  final String? toastEn;
  final String? toastRu;
  final String? toastTh;
  final String? toastJa;
  final Map<String, dynamic>? extra;

  IdeHints({this.toast, this.toastKo, this.toastEn, this.toastRu, this.toastTh, this.toastJa, this.extra});

  factory IdeHints.fromJson(Map<String, dynamic> json) => IdeHints(
        toast: json['toast']?.toString(),
        toastKo: json['toast_ko']?.toString(),
        toastEn: json['toast_en']?.toString(),
        toastRu: json['toast_ru']?.toString(),
        toastTh: json['toast_th']?.toString(),
        toastJa: json['toast_ja']?.toString(),
        extra: json,
      );

  String? selectToast(String preferred) {
    final lang = (preferred.isNotEmpty ? preferred : 'en').toLowerCase();
    final map = <String, String?>{
      'en': toastEn ?? toast,
      'ko': toastKo ?? toast,
      'ru': toastRu ?? toast,
      'th': toastTh ?? toast,
      'ja': toastJa ?? toast,
    };
    return map[lang] ?? toast;
  }
}
