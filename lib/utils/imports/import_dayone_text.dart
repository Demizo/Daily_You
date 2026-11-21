// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

const _momentReference = r'!?\[[^\]]*\]\(dayone-moment:[^)]*\)';
final _standaloneMoment =
    RegExp('^[ \\t]*(?:$_momentReference[ \\t]*)+\\n*', multiLine: true);
final _inlineMoment = RegExp(_momentReference);

final _escapeOrCode = RegExp(
    r'^```[\s\S]*?(?:^```|(?![\s\S]))|`[^`\n]*`|\\([!-/:-@\[-`{-~])',
    multiLine: true);
const _alwaysEscaped = r'\`*_[]<&|~';
const _escapedAtLineStart = '#>-+=';
const _escapedAfterNumber = '.)';
final _numberPrefix = RegExp(r'^\s*\d+$');
final _blockPrefix = RegExp(r'^[ \t>]*$');

String dayOneText(String text) {
  final withoutMedia = text
      .replaceAll(_standaloneMoment, '')
      .replaceAll(_inlineMoment, '')
      .trim();
  return withoutMedia.replaceAllMapped(_escapeOrCode, (match) {
    final character = match[1];
    if (character == null || _alwaysEscaped.contains(character)) {
      return match[0]!;
    }
    final lineStart = withoutMedia.lastIndexOf('\n', match.start) + 1;
    final prefix = withoutMedia.substring(lineStart, match.start);
    final guardsBlock = _blockPrefix.hasMatch(prefix) &&
        _escapedAtLineStart.contains(character);
    final guardsNumber = _numberPrefix.hasMatch(prefix) &&
        _escapedAfterNumber.contains(character);
    return guardsBlock || guardsNumber ? match[0]! : character;
  });
}
