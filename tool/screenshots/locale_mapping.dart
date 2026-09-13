// Maps ARB locale codes to fastlane locales directory names
const arbCodeToFastlaneLocale = <String, String>{
  'ar': 'ar',
  'be': 'be',
  'bg': 'bg',
  'cs': 'cs-CZ',
  'de': 'de',
  'en': 'en-US',
  'es': 'es-ES',
  'fa': 'fa-IR',
  'fr': 'fr-FR',
  'he': 'iw-IL',
  'hi': 'hi-IN',
  'id': 'id',
  'it': 'it-IT',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'lt': 'lt',
  'ms': 'ms-MY',
  'nl': 'nl-NL',
  'pl': 'pl-PL',
  'pt_BR': 'pt-BR',
  'sv': 'sv-SE',
  'ta': 'ta-IN',
  'tr': 'tr-TR',
  'uk': 'uk',
  'vi': 'vi',
  'zh': 'zh-CN',
  'zh_Hant': 'zh-TW',
};

// Excluded ARB locales with only placeholder-level translation coverage
const placeholderCoverageArbCodes = <String>{'nb', 'sv', 'be', 'bg'};

List<String> inScopeArbCodes() {
  final codes = arbCodeToFastlaneLocale.keys
      .where((code) => !placeholderCoverageArbCodes.contains(code))
      .toList();
  codes.sort();
  return codes;
}
