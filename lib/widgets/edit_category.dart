import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/color_swatch_row.dart';
import 'package:daily_you/widgets/delete_confirm_dialog.dart';
import 'package:daily_you/widgets/icon_picker_dialog.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

class EditCategory extends StatefulWidget {
  final TagCategory? category;

  const EditCategory({super.key, this.category});

  @override
  State<EditCategory> createState() => _EditCategoryState();
}

class _EditCategoryState extends State<EditCategory> {
  late TagNameEditingController _nameController;
  String? _icon;
  TagIconType _iconType = TagIconType.character;
  int? _color;

  @override
  void initState() {
    super.initState();
    _nameController =
        TagNameEditingController(text: widget.category?.name ?? '');
    _icon = widget.category?.icon;
    _iconType = widget.category?.iconType ?? TagIconType.character;
    _color = widget.category?.color;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = sanitizeTagName(_nameController.text);
    if (name.isEmpty) return;

    final now = DateTime.now();

    if (widget.category == null) {
      await TagsProvider.instance.addCategory(TagCategory(
        name: name,
        icon: _icon,
        iconType: _iconType,
        color: _color,
        timeCreate: now,
        timeModified: now,
      ));
    } else {
      // Construct directly so null icon is honored when cleared
      await TagsProvider.instance.updateCategory(TagCategory(
        id: widget.category!.id,
        name: name,
        icon: _icon,
        iconType: _iconType,
        color: _color,
        timeCreate: widget.category!.timeCreate,
        timeModified: now,
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final category = widget.category;
    if (category == null) return;
    final l10n = AppLocalizations.of(context)!;
    final tagCount = TagsProvider.instance.tags
        .where((tag) => tag.categoryId == category.id)
        .length;
    final confirmed = await showDeleteConfirmDialog(
      context,
      message: l10n.deleteCategoryMessage(tagCount, category.name),
    );
    if (confirmed && mounted) {
      await TagsProvider.instance.removeCategoryAndTags(category);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Color _effectiveColor(BuildContext context) =>
      _color != null ? Color(_color!) : Theme.of(context).colorScheme.onSurface;

  Future<void> _showIconPicker() async {
    final result = await showDialog<IconPickerResult>(
      context: context,
      builder: (context) => IconPickerDialog(
        previewColor: _effectiveColor(context),
      ),
    );
    if (result != null) {
      setState(() {
        _icon = result.value;
        _iconType = result.type;
      });
    }
  }

  Future<void> _showColorPicker() async {
    final result = await showDialog<ColorPickerResult>(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasIcon = _icon != null && _icon!.isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(widget.category == null
                ? l10n.newCategoryTitle
                : l10n.tagCategoryLabel),
          ),
          if (widget.category != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_rounded),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: _confirmDelete,
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: _showIconPicker,
                          child: Card.filled(
                            margin: EdgeInsets.zero,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: Center(
                              child: TagIconGlyph(
                                icon: _icon,
                                iconType: _iconType,
                                fallbackIcon: Icons.folder_rounded,
                                color: _effectiveColor(context),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        if (hasIcon)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _icon = null;
                                _iconType = TagIconType.character;
                              }),
                              child: const Icon(Icons.close, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card.filled(
                      margin: EdgeInsets.zero,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _nameController,
                          autofocus: widget.category == null,
                          maxLines: 1,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: l10n.nameHint,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) =>
                              sanitizeTagName(_nameController.text).isEmpty
                                  ? null
                                  : _save(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ColorSwatchRow(
                label: l10n.tagColorLabel,
                color: _effectiveColor(context),
                onTap: _showColorPicker,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed:
              sanitizeTagName(_nameController.text).isEmpty ? null : _save,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
