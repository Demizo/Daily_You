import 'package:flutter/material.dart';

class LanguageOption {
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  const LanguageOption({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });

  static final displayNameMapping = {
    LanguageOption(languageCode: "en"): "English",
    LanguageOption(languageCode: "ar"): "العربية",
    LanguageOption(languageCode: "da"): "dansk",
    LanguageOption(languageCode: "de"): "Deutsch",
    LanguageOption(languageCode: "es"): "español",
    LanguageOption(languageCode: "fr"): "français",
    LanguageOption(languageCode: "id"): "Indonesia",
    LanguageOption(languageCode: "oc"): "Occitan",
    LanguageOption(languageCode: "pl"): "polski",
    LanguageOption(languageCode: "pt", countryCode: "BR"): "português (Brasil)",
    LanguageOption(languageCode: "ru"): "русский",
    LanguageOption(languageCode: "tr"): "Türkçe",
    LanguageOption(languageCode: "uk"): "українська",
    LanguageOption(languageCode: "vi"): "Tiếng Việt",
    LanguageOption(languageCode: "zh"): "中文",
    LanguageOption(languageCode: "zh", scriptCode: "Hant"): "中文 (繁體)",
  };

  factory LanguageOption.fromLocale(Locale locale) => LanguageOption(
        languageCode: locale.languageCode,
        scriptCode: locale.scriptCode,
        countryCode: locale.countryCode,
      );

  factory LanguageOption.fromMap(Map<String, String?> map) => LanguageOption(
        languageCode: map['languageCode']!,
        scriptCode: map['scriptCode'],
        countryCode: map['countryCode'],
      );

  String displayName() {
    return displayNameMapping[this]!;
  }

  Map<String, String?> toMap() => {
        "languageCode": languageCode,
        "scriptCode": scriptCode,
        "countryCode": countryCode,
      };

  Locale toLocale() => Locale.fromSubtags(
        languageCode: languageCode,
        scriptCode: scriptCode,
        countryCode: countryCode,
      );

  @override
  bool operator ==(Object other) =>
      other is LanguageOption &&
      languageCode == other.languageCode &&
      scriptCode == other.scriptCode &&
      countryCode == other.countryCode;

  @override
  int get hashCode =>
      languageCode.hashCode ^
      (scriptCode?.hashCode ?? 0) ^
      (countryCode?.hashCode ?? 0);

  @override
  String toString() => toLocale().toLanguageTag();

  Map<String, String?> toJson() => toMap();

  factory LanguageOption.fromJson(Map<String, dynamic> json) =>
      LanguageOption.fromMap(json.map((k, v) => MapEntry(k, v as String?)));

  static LanguageOption? fromJsonOrNull(dynamic json) {
    if (json == null) return null;
    return LanguageOption.fromJson(json);
  }
}
