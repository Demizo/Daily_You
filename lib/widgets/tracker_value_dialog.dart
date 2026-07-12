import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showTrackerValueDialog(
  BuildContext context,
  Tag tag, {
  String? initialValue,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) =>
        _TrackerValueDialog(tag: tag, initialValue: initialValue),
  );
  return (result == null || result.isEmpty) ? null : result;
}

class _TrackerValueDialog extends StatefulWidget {
  final Tag tag;
  final String? initialValue;

  const _TrackerValueDialog({required this.tag, this.initialValue});

  @override
  State<_TrackerValueDialog> createState() => _TrackerValueDialogState();
}

class _TrackerValueDialogState extends State<_TrackerValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => double.tryParse(_controller.text.trim()) != null;

  List<String> _frequentValues() {
    if (widget.tag.id == null) return [];
    final counts = <String, int>{};
    for (final entryTag in TagsProvider.instance.entryTags) {
      if (entryTag.tagId == widget.tag.id &&
          entryTag.value != null &&
          entryTag.value!.isNotEmpty) {
        counts[entryTag.value!] = (counts[entryTag.value!] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final freqCompare = b.value.compareTo(a.value);
        if (freqCompare != 0) return freqCompare;
        final aNum = double.tryParse(a.key) ?? 0;
        final bNum = double.tryParse(b.key) ?? 0;
        return aNum.compareTo(bNum);
      });
    return sorted.take(10).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final frequent = _frequentValues();
    return AlertDialog(
      title: Text(widget.tag.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card.filled(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                decoration: const InputDecoration(border: InputBorder.none),
                onSubmitted: (_) {
                  if (_isValid) {
                    Navigator.of(context).pop(_controller.text.trim());
                  }
                },
              ),
            ),
          ),
          if (frequent.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: frequent.map((v) {
                return ActionChip(
                  label: Text(v),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  onPressed: () => setState(() => _controller.text = v),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
