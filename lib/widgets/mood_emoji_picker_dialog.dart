// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/utils/emoji_catalog.dart';
import 'package:material_ui/material_ui.dart';

class MoodEmojiPickerDialog extends StatefulWidget {
  final String? currentEmoji;

  const MoodEmojiPickerDialog({super.key, this.currentEmoji});

  static Future<String?> show(BuildContext context, {String? currentEmoji}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MoodEmojiPickerDialog(currentEmoji: currentEmoji),
    );
  }

  @override
  State<MoodEmojiPickerDialog> createState() => _MoodEmojiPickerDialogState();
}

class _MoodEmojiPickerDialogState extends State<MoodEmojiPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<EmojiItem> _filtered = EmojiCatalog.moodEmojis;
  List<String> _recents = [];

  @override
  void initState() {
    super.initState();
    _recents = EmojiCatalog.getRecents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filtered = EmojiCatalog.search(_searchController.text);
    });
  }

  Future<void> _selectEmoji(String emoji) async {
    await EmojiCatalog.addRecent(emoji);
    if (mounted) {
      Navigator.of(context).pop(emoji);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Emoji',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search emojis…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
          if (_recents.isNotEmpty && _searchController.text.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Recent',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final emoji = _recents[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _selectEmoji(emoji),
                    child: Container(
                      width: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching emojis',
                      style: TextStyle(color: theme.disabledColor),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      final isSelected = widget.currentEmoji == item.emoji;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectEmoji(item.emoji),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.primary, width: 2)
                                : null,
                          ),
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
