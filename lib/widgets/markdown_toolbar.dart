import 'package:flutter/material.dart';

class MarkdownToolbar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<MarkdownToolbar> createState() => _MarkdownToolbarState();
}

class _MarkdownToolbarState extends State<MarkdownToolbar> {
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => _onTextChanged());
    _lastText = widget.controller.text;
  }

  void _onTextChanged() {
    final controller = widget.controller;
    final currentText = controller.text;
    final selection = controller.selection;

    if (_lastText.length + 1 == currentText.length &&
        selection.baseOffset == selection.extentOffset &&
        selection.baseOffset > 0 &&
        currentText[selection.baseOffset - 1] == '\n') {
      _handleEnter();
    }
    _lastText = controller.text;
  }

  void _handleEnter() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursor = selection.baseOffset;

    if (cursor == 0 || cursor > text.length) return;

    final beforeCursor = text.substring(0, cursor);

    final lines = beforeCursor.split('\n');
    if (lines.length < 2) return;

    final prevLineStartOffset = beforeCursor.lastIndexOf(
            '\n', beforeCursor.length - lines.last.length - 2) +
        1;
    final previousLine = lines[lines.length - 2];

    final emptyBulletMatch = RegExp(r'^(\s*)-\s*$').firstMatch(previousLine);

    if (emptyBulletMatch != null) {
      // Previous bullet point is empty, remove it
      final startOfBullet = prevLineStartOffset;
      final endOfBullet = cursor; // Include the new line
      final newText = text.replaceRange(startOfBullet, endOfBullet, '');
      final newCursor = startOfBullet;

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    } else {
      final bulletMatch = RegExp(r'^(\s*)-\s').firstMatch(previousLine);

      if (bulletMatch != null) {
        // Start a new bullet point under the previous line
        final whitespace = bulletMatch.group(1) ?? '';
        final insertText = '$whitespace- ';
        final newText = text.replaceRange(cursor, cursor, insertText);
        final newCursor = cursor + insertText.length;

        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursor),
        );
      }
    }

    widget.focusNode.requestFocus();
  }

  void _wrapSelection(String left, [String? right]) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    var start = selection.start;
    var end = selection.end;

    // Text has not been selected yet, use the end of the text
    if (start == -1 && end == -1) {
      start = widget.controller.text.length;
      end = widget.controller.text.length;
    }

    final before = text.substring(0, start);
    final selected = text.substring(start, end);
    final after = text.substring(end);

    final wrapRight = right ?? left;

    final newText = '$before$left$selected$wrapRight$after';
    widget.controller.value = TextEditingValue(
      text: newText,
      selection:
          TextSelection.collapsed(offset: (before + left + selected).length),
    );
    widget.focusNode.requestFocus();
  }

  void _insertLinePrefix(String prefix) {
    final lines = widget.controller.text.split('\n');
    final selection = widget.controller.selection;
    var start = selection.start;

    // Text has not been selected yet, use the end of the text
    if (start == -1) {
      start = widget.controller.text.length;
    }

    final currentLineIndex =
        widget.controller.text.substring(0, start).split('\n').length - 1;

    lines[currentLineIndex] = '$prefix ${lines[currentLineIndex]}';
    final newText = lines.join('\n');
    widget.controller.text = newText;
    widget.controller.selection =
        TextSelection.collapsed(offset: start + prefix.length + 1);
    widget.focusNode.requestFocus();
  }

  void _showHeaderDialog() {
    showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (i) {
            final level = i + 1;
            return ListTile(
              title: Text('H$level',
                  style: TextStyle(fontSize: (28 - (2 * level.toDouble())))),
              onTap: () {
                Navigator.pop(context, level);
              },
            );
          }),
        ),
      ),
    ).then((level) {
      if (level != null) {
        _insertLinePrefix('#' * level);
      }
    });
  }

  Widget _buildButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 24,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.text_fields,
            onPressed: _showHeaderDialog,
          ),
          _buildButton(
            icon: Icons.format_bold,
            onPressed: () => _wrapSelection('**'),
          ),
          _buildButton(
            icon: Icons.format_italic,
            onPressed: () => _wrapSelection('_'),
          ),
          _buildButton(
            icon: Icons.format_strikethrough,
            onPressed: () => _wrapSelection('~~'),
          ),
          _buildButton(
            icon: Icons.format_list_bulleted,
            onPressed: () => _insertLinePrefix('-'),
          ),
          _buildButton(
            icon: Icons.link_rounded,
            onPressed: () => _wrapSelection('[', ']()'),
          ),
          _buildButton(
            icon: Icons.format_quote,
            onPressed: () => _insertLinePrefix('>'),
          ),
        ],
      ),
    );
  }
}
