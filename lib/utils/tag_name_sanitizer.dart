import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final RegExp bannedTagNameCharacters = RegExp(r'''[\\/"'`#\[\]{},:]''');

String sanitizeTagName(String input) {
  final withoutBannedCharacters = input.replaceAll(bannedTagNameCharacters, '');
  final withCollapsedWhitespace =
      withoutBannedCharacters.replaceAll(RegExp(r'\s+'), ' ');
  return withCollapsedWhitespace.trim();
}

class TagNameEditingController extends TextEditingController {
  TagNameEditingController({super.text});

  static final TextInputFormatter _formatter =
      FilteringTextInputFormatter.deny(bannedTagNameCharacters);

  @override
  set value(TextEditingValue newValue) {
    super.value = _formatter.formatEditUpdate(value, newValue);
  }
}
