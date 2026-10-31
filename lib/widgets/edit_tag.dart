// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/connected_button_group.dart';
import 'package:daily_you/widgets/delete_confirm_dialog.dart';
import 'package:daily_you/widgets/edit_category.dart';
import 'package:daily_you/widgets/icon_color_label_row.dart';
import 'package:daily_you/widgets/icon_picker_dialog.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

class EditTag extends StatefulWidget {
  final Tag? tag;
  final String? initialName;

  const EditTag({super.key, this.tag, this.initialName});

  @override
  State<EditTag> createState() => _EditTagState();
}

class _EditTagState extends State<EditTag> {
  late TagNameEditingController _nameController;
  late TagType _tagType;
  String? _icon;
  TagIconType _iconType = TagIconType.character;
  int? _color;
  int? _categoryId;

  bool _colorInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TagNameEditingController(
        text: widget.tag?.name ?? widget.initialName ?? '');
    _icon = widget.tag?.icon;
    _iconType = widget.tag?.iconType ?? TagIconType.character;
    _tagType = widget.tag?.tagType ?? TagType.label;
    _categoryId = widget.tag?.categoryId;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_colorInitialized) {
      _color = widget.tag?.color;
      _colorInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _effectiveColor(BuildContext context) =>
      _color != null ? Color(_color!) : Theme.of(context).colorScheme.secondary;

  Future<void> _save() async {
    final name = sanitizeTagName(_nameController.text);
    if (name.isEmpty) return;

    final now = DateTime.now();

    if (widget.tag == null) {
      await TagsProvider.instance.add(Tag(
        name: name,
        color: _color,
        tagType: _tagType,
        icon: _icon,
        iconType: _iconType,
        categoryId: _categoryId,
        timeCreate: now,
        timeModified: now,
      ));
    } else {
      // Construct directly so categoryId: null is honored
      await TagsProvider.instance.update(Tag(
        id: widget.tag!.id,
        name: name,
        color: _color,
        tagType: widget.tag!.tagType,
        icon: _icon,
        iconType: _iconType,
        categoryId: _categoryId,
        timeCreate: widget.tag!.timeCreate,
        timeModified: now,
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final tag = widget.tag;
    if (tag == null) return;
    final l10n = AppLocalizations.of(context)!;
    final entryCount = TagsProvider.instance.entryCountForTag(tag.id!);
    final confirmed = await showDeleteConfirmDialog(
      context,
      message: l10n.deleteTagMessage(entryCount, tag.name),
    );
    if (confirmed && mounted) {
      await TagsProvider.instance.remove(tag);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _showColorPicker() async {
    final result = await showAppDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: _color != null ? Color(_color!) : null,
        showNoneOption: true,
      ),
    );
    if (result != null) {
      setState(() => _color = result.color?.toARGB32());
    }
  }

  Future<void> _showIconPicker() async {
    final result = await showAppDialog<IconPickerResult>(
      context: context,
      builder: (context) => IconPickerDialog(
        previewColor: _effectiveColor(context),
        initial: (type: _iconType, value: _icon),
      ),
    );
    if (result != null) {
      setState(() {
        _icon = result.value;
        _iconType = result.type;
      });
    }
  }

  Widget _buildTypeSection(BuildContext context, AppLocalizations l10n) {
    if (widget.tag != null) {
      final typeLabel = switch (widget.tag!.tagType) {
        TagType.label => l10n.tagTypeLabelTitle,
        TagType.tracker => l10n.tagTypeTrackerTitle,
      };
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                side: BorderSide.none,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                label: Text(typeLabel),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_rounded),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: _confirmDelete,
          ),
        ],
      );
    }
    return ConnectedButtonGroup(
      labels: [l10n.tagTypeLabelTitle, l10n.tagTypeTrackerTitle],
      selectedIndex: _tagType == TagType.label ? 0 : 1,
      onSelectionChanged: (selectedIndex) => setState(() =>
          _tagType = selectedIndex == 0 ? TagType.label : TagType.tracker),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    final tagColor = _effectiveColor(context);
    final fallbackIcon = _tagType == TagType.tracker
        ? Icons.timeline_rounded
        : Icons.label_rounded;
    return IconColorLabelRow(
      icon: TagIconGlyph(
        icon: _icon,
        iconType: _iconType,
        fallbackIcon: fallbackIcon,
        color: tagColor,
        size: 28,
      ),
      color: tagColor,
      controller: _nameController,
      hintText: AppLocalizations.of(context)!.nameHint,
      autofocus: widget.tag == null,
      onPickIcon: _showIconPicker,
      onPickColor: _showColorPicker,
    );
  }

  Future<void> _createCategory(BuildContext context) async {
    final categoriesBefore =
        List<TagCategory>.from(TagsProvider.instance.categories);
    await showAppDialog(
      context: context,
      builder: (_) => const EditCategory(category: null),
    );
    final newCategory = TagsProvider.instance.categories
        .where((c) => categoriesBefore.every((b) => b.id != c.id))
        .firstOrNull;
    if (newCategory != null && mounted) {
      setState(() => _categoryId = newCategory.id);
    }
  }

  Widget _buildCategoryRow(BuildContext context, List<TagCategory> categories) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsChoiceRow<int?>(
      icon: Icons.folder_rounded,
      title: l10n.tagCategoryLabel,
      value: _categoryId,
      options: {
        null: l10n.noTemplateTitle,
        for (final category in categories) category.id: category.name,
      },
      onChanged: (categoryId) => setState(() => _categoryId = categoryId),
      action: (
        label: l10n.newCategoryTitle,
        onPressed: () => _createCategory(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = TagsProvider.instance.categories;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = (screenWidth - 80).clamp(280.0, 400.0);
    const contentPadding = EdgeInsets.symmetric(horizontal: 24);
    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: contentPadding,
                child: _buildTypeSection(context, l10n),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: contentPadding,
                child: _buildTopRow(context),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: settingsDialogRowInset,
                ),
                child: _buildCategoryRow(context, categories),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: contentPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      onPressed: sanitizeTagName(_nameController.text).isEmpty
                          ? null
                          : _save,
                      child:
                          Text(MaterialLocalizations.of(context).okButtonLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
