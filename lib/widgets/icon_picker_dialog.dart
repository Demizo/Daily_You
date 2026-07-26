import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Result of [IconPickerDialog]: either a curated material icon (identified
/// by its stable registry key) or a free-typed character/emoji.
typedef IconPickerResult = ({TagIconType type, String value});

/// Dialog letting the user pick either a curated Material icon or type a
/// custom character/emoji, shared by the tag and category editors.
class IconPickerDialog extends StatefulWidget {
  final Color previewColor;

  const IconPickerDialog({super.key, required this.previewColor});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
    _searchController.addListener(() => setState(() {}));
    _customController.addListener(() => setState(() {}));
  }

  void _onTabChanged() {
    setState(() {});
    if (_tabController.index == 0) {
      _customFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _customController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  void _selectIcon(String key) {
    Navigator.of(context).pop((type: TagIconType.materialIcon, value: key));
  }

  void _confirmCustom() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop((type: TagIconType.character, value: value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim().toLowerCase();

    final groups = tagIconGroups
        .map((group) => (
              id: group.id,
              keys: group.keys
                  .where((key) => query.isEmpty || key.contains(query))
                  .toList(),
            ))
        .where((group) => group.keys.isNotEmpty)
        .toList();

    final canConfirmCustom =
        _tabController.index == 1 && _customController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(l10n.iconPickerTitle),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.iconPickerIconsTab),
                Tab(text: l10n.iconPickerCustomTab),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIconsTab(context, l10n, groups),
                  _buildCustomTab(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: canConfirmCustom ? _confirmCustom : null,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }

  Widget _buildIconsTab(
    BuildContext context,
    AppLocalizations l10n,
    List<({TagIconGroupId id, List<String> keys})> groups,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SearchBar(
            controller: _searchController,
            hintText: l10n.iconPickerSearchHint,
            elevation: const WidgetStatePropertyAll(0),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.only(left: 4, right: 4),
            ),
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.secondaryContainer,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    l10n.noResults,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final group in groups) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          tagIconGroupLabel(l10n, group.id),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 48,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: group.keys.length,
                        itemBuilder: (context, index) {
                          final key = group.keys[index];
                          return IconButton(
                            icon: Icon(tagIconRegistry[key],
                                color: widget.previewColor),
                            onPressed: () => _selectIcon(key),
                          );
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCustomTab(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.moodIconPrompt,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card.filled(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Center(
                child: TextField(
                  controller: _customController,
                  focusNode: _customFocusNode,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                  inputFormatters: [LengthLimitingTextInputFormatter(1)],
                  onSubmitted: (_) => _confirmCustom(),
                  decoration: const InputDecoration(
                    hintText: '?',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
