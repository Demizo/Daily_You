import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/color_swatch_row.dart';
import 'package:daily_you/widgets/connected_button_group.dart';
import 'package:daily_you/widgets/delete_confirm_dialog.dart';
import 'package:daily_you/widgets/edit_category.dart';
import 'package:daily_you/widgets/icon_picker_dialog.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:flutter/material.dart';
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

  Future<void> _showIconPicker() async {
    final result = await showDialog<IconPickerResult>(
      context: context,
      builder: (context) =>
          IconPickerDialog(previewColor: _effectiveColor(context)),
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
    final hasIcon = _icon != null && _icon!.isNotEmpty;
    final tagColor = _effectiveColor(context);
    final fallbackIcon = _tagType == TagType.tracker
        ? Icons.timeline_rounded
        : Icons.label_rounded;
    return IntrinsicHeight(
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
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: TagIconGlyph(
                        icon: _icon,
                        iconType: _iconType,
                        fallbackIcon: fallbackIcon,
                        color: tagColor,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  autofocus: widget.tag == null,
                  controller: _nameController,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.nameHint,
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

  Widget _buildColorRow(BuildContext context) {
    return ColorSwatchRow(
      label: AppLocalizations.of(context)!.tagColorLabel,
      color: _effectiveColor(context),
      onTap: _showColorPicker,
    );
  }

  Future<void> _createCategory(BuildContext context) async {
    final categoriesBefore =
        List<TagCategory>.from(TagsProvider.instance.categories);
    await showDialog(
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
    return Row(
      children: [
        Text(
          l10n.tagCategoryLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<int?>(
            value: _categoryId,
            isDense: true,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            elevation: 1,
            borderRadius: BorderRadius.circular(20),
            alignment: AlignmentDirectional.centerEnd,
            onChanged: (value) async {
              if (value == -1) {
                await _createCategory(context);
              } else {
                setState(() => _categoryId = value);
              }
            },
            items: [
              DropdownMenuItem<int?>(
                value: null,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(l10n.noTemplateTitle,
                    overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
              ),
              ...categories.map(
                (c) => DropdownMenuItem<int?>(
                  value: c.id,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(c.name,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      maxLines: 1),
                ),
              ),
              DropdownMenuItem<int?>(
                value: -1,
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16),
                    const SizedBox(width: 6),
                    Text(l10n.newCategoryTitle,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = TagsProvider.instance.categories;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth - 80).clamp(280.0, 400.0);
    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeSection(context, l10n),
              const SizedBox(height: 12),
              _buildTopRow(context),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildColorRow(context),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildCategoryRow(context, categories),
              ),
              const SizedBox(height: 24),
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
