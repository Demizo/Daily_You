import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _ToolbarEntry {
  final double width;
  final bool isDivider;
  final String? group;
  final Widget Function(BuildContext context, VoidCallback? closePopup) build;

  const _ToolbarEntry({
    required this.width,
    required this.isDivider,
    this.group,
    required this.build,
  });
}

class MarkdownToolbar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final UndoHistoryController? undoController;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.undoController,
  });

  @override
  State<MarkdownToolbar> createState() => _MarkdownToolbarState();
}

class _MarkdownToolbarState extends State<MarkdownToolbar> {
  static const double _buttonWidth = 40.0;
  static const double _dividerWidth = 8.0;
  static const double _cardHorizontalPadding = 12.0;
  static const double _wideBreakpoint = 600.0;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _lastText = widget.controller.text;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
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
      final startOfBullet = prevLineStartOffset;
      final endOfBullet = cursor;
      final newText = text.replaceRange(startOfBullet, endOfBullet, '');
      final newCursor = startOfBullet;

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    } else {
      final bulletMatch = RegExp(r'^(\s*)-\s').firstMatch(previousLine);

      if (bulletMatch != null) {
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

  List<(IconData, VoidCallback)> _formatButtonSpecs() => [
        (Icons.text_fields_rounded, _showHeaderDialog),
        (Icons.format_bold_rounded, () => _wrapSelection('**')),
        (Icons.format_italic_rounded, () => _wrapSelection('_')),
        (Icons.format_strikethrough_rounded, () => _wrapSelection('~~')),
        (Icons.format_list_bulleted_rounded, () => _insertLinePrefix('-')),
        (Icons.link_rounded, () => _wrapSelection('[', ']()')),
        (Icons.format_quote_rounded, () => _insertLinePrefix('>')),
      ];

  List<_ToolbarEntry> _buildEntries(
      bool showMarkdown, ConfigProvider configProvider) {
    final entries = <_ToolbarEntry>[];

    void addDivider() {
      entries.add(_ToolbarEntry(
        width: _dividerWidth,
        isDivider: true,
        build: (_, __) => const VerticalDivider(width: 8, thickness: 1),
      ));
    }

    // Markdown controls
    for (final (icon, action) in _formatButtonSpecs()) {
      entries.add(_ToolbarEntry(
        width: _buttonWidth,
        isDivider: false,
        build: (ctx, closePopup) => IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 24),
          onPressed: () {
            closePopup?.call();
            action();
          },
        ),
      ));
    }

    // Undo / redo
    if (widget.undoController != null) {
      if (entries.isNotEmpty) addDivider();
      final uc = widget.undoController!;
      for (final isUndo in [true, false]) {
        entries.add(_ToolbarEntry(
          width: _buttonWidth,
          isDivider: false,
          group: 'undo',
          build: (ctx, closePopup) => ValueListenableBuilder<UndoHistoryValue>(
            valueListenable: uc,
            builder: (ctx, value, _) {
              final canAct = isUndo ? value.canUndo : value.canRedo;
              return IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(isUndo ? Icons.undo_rounded : Icons.redo_rounded,
                    size: 24),
                onPressed: canAct
                    ? () {
                        closePopup?.call();
                        isUndo ? uc.undo() : uc.redo();
                      }
                    : null,
              );
            },
          ),
        ));
      }
    }

    // Hide / show toggle
    if (entries.isNotEmpty) addDivider();
    entries.add(_ToolbarEntry(
      width: _buttonWidth,
      isDivider: false,
      build: (ctx, closePopup) => IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          showMarkdown
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
          size: 24,
        ),
        onPressed: () {
          closePopup?.call();
          configProvider.set(ConfigKey.useMarkdownToolbar, !showMarkdown);
        },
      ),
    ));

    return entries;
  }

  void _showOverflowPopup(
      BuildContext buttonContext, List<_ToolbarEntry> overflowEntries) {
    final button = buttonContext.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(buttonContext)
        .overlay!
        .context
        .findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero, ancestor: overlay) & button.size,
      Offset.zero & overlay.size,
    );

    // Size the popup to exactly fit its buttons + 8px (4px padding each side).
    final contentWidth =
        overflowEntries.fold(0.0, (sum, e) => sum + e.width) + 8;
    final maxScreenWidth = MediaQuery.of(buttonContext).size.width * 0.9;
    final popupWidth = contentWidth.clamp(0.0, maxScreenWidth);

    showMenu<void>(
      context: buttonContext,
      position: position,
      constraints: BoxConstraints.tightFor(width: popupWidth),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          height: 0,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: IconTheme.merge(
              data: const IconThemeData(opacity: 1.0),
              child: Builder(
                builder: (popupCtx) => IntrinsicHeight(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final entry in overflowEntries)
                          entry.build(popupCtx, () => Navigator.pop(popupCtx)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Card _wrapInCard(BuildContext context, Widget child) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: child,
      ),
    );
  }

  Widget _filledOverflowButton(
      BuildContext context, List<_ToolbarEntry> overflowEntries) {
    return Builder(
      builder: (btnCtx) => IconButton(
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(btnCtx).colorScheme.primaryContainer,
          foregroundColor: Theme.of(btnCtx).colorScheme.onPrimaryContainer,
        ),
        icon: const Icon(Icons.more_horiz_rounded, size: 24),
        onPressed: () => _showOverflowPopup(btnCtx, overflowEntries),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, configProvider, _) {
        final showMarkdown = configProvider.get(ConfigKey.useMarkdownToolbar);
        final allEntries = _buildEntries(showMarkdown, configProvider);

        if (!showMarkdown) {
          return UnconstrainedBox(
            alignment: AlignmentDirectional.centerStart,
            child: _filledOverflowButton(context, allEntries),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideBreakpoint;
            final alignment = isWide
                ? AlignmentDirectional.center
                : AlignmentDirectional.centerStart;

            final totalWidth = allEntries.fold(0.0, (sum, e) => sum + e.width);

            int splitIndex;
            bool hasOverflowButton;

            if (totalWidth + _cardHorizontalPadding <= constraints.maxWidth) {
              splitIndex = allEntries.length;
              hasOverflowButton = false;
            } else {
              hasOverflowButton = true;
              double used = _buttonWidth + _cardHorizontalPadding;
              splitIndex = 0;
              for (final entry in allEntries) {
                if (used + entry.width <= constraints.maxWidth) {
                  used += entry.width;
                  splitIndex++;
                } else {
                  break;
                }
              }

              // Don't end the visible section on a divider.
              while (splitIndex > 0 && allEntries[splitIndex - 1].isDivider) {
                splitIndex--;
              }

              // Ensure grouped entries (e.g. undo/redo) are never split across
              // visible and overflow.
              final visibleGroups = allEntries
                  .sublist(0, splitIndex)
                  .where((e) => e.group != null)
                  .map((e) => e.group!)
                  .toSet();
              final overflowGroups = allEntries
                  .sublist(splitIndex)
                  .where((e) => e.group != null)
                  .map((e) => e.group!)
                  .toSet();
              final splitGroups = visibleGroups.intersection(overflowGroups);
              if (splitGroups.isNotEmpty) {
                while (splitIndex > 0 &&
                    splitGroups.contains(allEntries[splitIndex - 1].group)) {
                  splitIndex--;
                }
                while (splitIndex > 0 && allEntries[splitIndex - 1].isDivider) {
                  splitIndex--;
                }
              }
            }

            final visibleEntries = allEntries.sublist(0, splitIndex);

            // Skip leading dividers in the overflow section.
            var overflowStart = splitIndex;
            while (overflowStart < allEntries.length &&
                allEntries[overflowStart].isDivider) {
              overflowStart++;
            }
            final overflowEntries = hasOverflowButton
                ? allEntries.sublist(overflowStart)
                : <_ToolbarEntry>[];

            final toolbarRow = IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in visibleEntries)
                    entry.build(context, null),
                  if (hasOverflowButton)
                    Builder(
                      builder: (btnCtx) => IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.more_horiz_rounded, size: 24),
                        onPressed: () =>
                            _showOverflowPopup(btnCtx, overflowEntries),
                      ),
                    ),
                ],
              ),
            );

            return UnconstrainedBox(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _wrapInCard(context, toolbarRow),
              ),
            );
          },
        );
      },
    );
  }
}
