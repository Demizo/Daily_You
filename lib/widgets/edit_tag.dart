import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/connected_button_group.dart';
import 'package:daily_you/widgets/edit_category.dart';
import 'package:daily_you/widgets/icon_picker_dialog.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class EditTag extends StatefulWidget {
  final Tag? tag;
  final String? initialName;

  const EditTag({super.key, this.tag, this.initialName});

  @override
  State<EditTag> createState() => _EditTagState();
}

class _EditTagState extends State<EditTag> {
  late TextEditingController _nameController;
  late TagType _tagType;
  String? _icon;
  TagIconType _iconType = TagIconType.character;
  int? _color;
  int? _categoryId;

  bool _colorInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
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
      final tagColor = widget.tag?.color;
      _color = (tagColor == null || tagColor == 0) ? null : tagColor;
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
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final colorToStore = _color ?? 0;

    if (widget.tag == null) {
      await TagsProvider.instance.add(Tag(
        name: name,
        color: colorToStore,
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
        color: colorToStore,
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

  void _showColorPicker() {
    Color pickerColor = _effectiveColor(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
            onPressed: () {
              setState(() => _color = pickerColor.toARGB32());
              Navigator.pop(context);
            },
          ),
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              enableAlpha: false,
              labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
              paletteType: PaletteType.hueWheel,
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
            ),
          ],
        ),
      ),
    );
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
      return Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(typeLabel),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _showIconPicker,
              child: Card.filled(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SizedBox(
                  width: 44,
                  height: 44,
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card.filled(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _nameController,
                maxLines: 1,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.tagNameHint,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.tagColorLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_color != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _color = null),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showColorPicker,
              child: CircleAvatar(
                backgroundColor: _effectiveColor(context),
                radius: 16,
              ),
            ),
          ],
        ),
      ],
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
        Expanded(
          child: Text(
            l10n.tagCategoryLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        DropdownButton<int?>(
          value: _categoryId,
          isDense: true,
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
              child: Text(l10n.tagCategoryNone),
            ),
            ...categories.map(
              (c) => DropdownMenuItem<int?>(
                value: c.id,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(c.name),
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
                  Text(l10n.newCategoryTitle),
                ],
              ),
            ),
          ],
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
              _buildColorRow(context),
              const SizedBox(height: 8),
              _buildCategoryRow(context, categories),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    onPressed:
                        _nameController.text.trim().isEmpty ? null : _save,
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
