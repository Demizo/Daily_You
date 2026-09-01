import 'package:flutter/widgets.dart';

/// Replaces the selection, or appends when there is no cursor.
void insertAtCursor(TextEditingController controller, String text) {
  final current = controller.text;
  final selection = controller.selection;
  final start = selection.isValid ? selection.start : current.length;
  final end = selection.isValid ? selection.end : current.length;

  controller.value = TextEditingValue(
    text: current.replaceRange(start, end, text),
    selection: TextSelection.collapsed(offset: start + text.length),
  );
}

void insertTemplateText(TextEditingController controller, String text,
    {required bool hasFocus}) {
  if (controller.text.isEmpty) {
    controller.text = text;
  } else if (hasFocus) {
    insertAtCursor(controller, text);
  } else {
    controller.value = TextEditingValue(
      text: '${controller.text}\n$text',
      selection: TextSelection.collapsed(
          offset: controller.text.length + 1 + text.length),
    );
  }
}

void wrapSelection(TextEditingController controller, String left,
    [String? right]) {
  final text = controller.text;
  final selection = controller.selection;
  final start = selection.isValid ? selection.start : text.length;
  final end = selection.isValid ? selection.end : text.length;

  final before = text.substring(0, start);
  final selected = text.substring(start, end);
  final after = text.substring(end);
  final closing = right ?? left;

  controller.value = TextEditingValue(
    text: '$before$left$selected$closing$after',
    selection:
        TextSelection.collapsed(offset: start + left.length + selected.length),
  );
}

void insertLinePrefix(TextEditingController controller, String prefix) {
  final text = controller.text;
  final selection = controller.selection;
  final cursor = selection.isValid ? selection.start : text.length;

  final lines = text.split('\n');
  final lineIndex = text.substring(0, cursor).split('\n').length - 1;
  lines[lineIndex] = '$prefix ${lines[lineIndex]}';

  controller.value = TextEditingValue(
    text: lines.join('\n'),
    selection: TextSelection.collapsed(offset: cursor + prefix.length + 1),
  );
}

class BulletListContinuation {
  BulletListContinuation(this._controller) : _previousText = _controller.text {
    _controller.addListener(_handleTextChanged);
  }

  static final RegExp _emptyBulletLine = RegExp(r'^(\s*)-\s*$');
  static final RegExp _bulletLine = RegExp(r'^(\s*)-\s');

  final TextEditingController _controller;
  String _previousText;

  void dispose() => _controller.removeListener(_handleTextChanged);

  void _handleTextChanged() {
    final text = _controller.text;
    final typedNewline = _isSingleTypedNewline(text);
    // Updated before the edit below, which re-enters this listener.
    _previousText = text;
    if (typedNewline) _continueBullet();
  }

  bool _isSingleTypedNewline(String text) {
    final selection = _controller.selection;
    final cursor = selection.baseOffset;
    if (!selection.isCollapsed || cursor <= 0 || cursor > text.length) {
      return false;
    }
    if (text[cursor - 1] != '\n') return false;

    final previous = _previousText;
    final tailLength = text.length - cursor;
    final oldTailStart = previous.length - tailLength;
    if (oldTailStart < 0 ||
        previous.substring(oldTailStart) != text.substring(cursor)) {
      return false;
    }

    var prefixLength = 0;
    final maxPrefix = cursor - 1 < oldTailStart ? cursor - 1 : oldTailStart;
    while (prefixLength < maxPrefix &&
        text[prefixLength] == previous[prefixLength]) {
      prefixLength++;
    }

    // Some keyboards replace a trailing autocorrect space with the newline,
    // or insert one alongside it, rather than purely appending "\n".
    final newMiddle = text.substring(prefixLength, cursor - 1);
    final oldMiddle = previous.substring(prefixLength, oldTailStart);
    return newMiddle.trim().isEmpty && oldMiddle.trim().isEmpty;
  }

  void _continueBullet() {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final beforeCursor = text.substring(0, cursor);

    final lines = beforeCursor.split('\n');
    if (lines.length < 2) return;
    final bulletedLine = lines[lines.length - 2];

    if (_emptyBulletLine.hasMatch(bulletedLine)) {
      // beforeCursor ends with the newline just typed.
      final lineStart = beforeCursor.length - 1 - bulletedLine.length;
      _setText(text.replaceRange(lineStart, cursor, ''), lineStart);
      return;
    }

    final bullet = _bulletLine.firstMatch(bulletedLine);
    if (bullet == null) return;
    final indent = bullet.group(1) ?? '';
    final newBullet = '$indent- ';
    _setText(text.replaceRange(cursor, cursor, newBullet),
        cursor + newBullet.length);
  }

  void _setText(String text, int cursor) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
