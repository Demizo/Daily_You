import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/widgets/delete_confirm_dialog.dart';
import 'package:daily_you/widgets/edit_toolbar.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/tag_grouped_chip_list.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/template_variable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class EditTemplate extends StatefulWidget {
  final Template? template;

  const EditTemplate({super.key, this.template});

  @override
  State<EditTemplate> createState() => _EditTemplateState();
}

class _EditTemplateState extends State<EditTemplate> {
  late TextEditingController _nameController;
  late String templateText;
  late final TagAttachmentSource _tagSource;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final UndoHistoryController _undoController = UndoHistoryController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    if (widget.template != null) {
      templateText = widget.template!.text ?? "";
    } else {
      templateText = "";
    }
    final initialTagIds = widget.template?.id == null
        ? <int>[]
        : TagsProvider.instance
            .getTemplateTagsForTemplate(widget.template!.id!)
            .map((templateTag) => templateTag.tagId)
            .toList();
    _tagSource = TagAttachmentSource(initialTagIds: initialTagIds);
    _textEditingController
        .addListener(() => templateText = _textEditingController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagSource.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    final int templateId;
    if (widget.template == null) {
      final created = await TemplatesProvider.instance.add(Template(
          name: _nameController.text,
          text: templateText,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()));
      templateId = created.id!;
    } else {
      final updated = widget.template!.copy(
          name: _nameController.text,
          text: templateText,
          timeModified: DateTime.now());
      await TemplatesProvider.instance.update(updated);
      templateId = updated.id!;
    }
    await TagsProvider.instance
        .setTemplateTags(templateId, _tagSource.attachedTagIds);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final template = widget.template;
    if (template == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmDialog(
      context,
      message: l10n.deleteTemplateMessage(template.name),
    );
    if (confirmed && mounted) {
      final defaultTemplateId =
          ConfigProvider.instance.get(ConfigKey.defaultTemplate) as int?;
      if (defaultTemplateId == template.id) {
        await ConfigProvider.instance.set(ConfigKey.defaultTemplate, -1);
      }
      await TemplatesProvider.instance.remove(template);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openTagPicker() async {
    await showDialog(
      context: context,
      builder: (_) =>
          TagPickerDialog(mode: TagPickerMode.attach, source: _tagSource),
    );
  }

  Widget _buildTagChips() {
    return ListenableBuilder(
      listenable: _tagSource,
      builder: (context, _) {
        final attachedIds = _tagSource.attachedTagIds;
        if (attachedIds.isEmpty) return const SizedBox.shrink();
        final tagsProvider = Provider.of<TagsProvider>(context);
        final attachedSet = attachedIds.toSet();
        final tagPool = tagsProvider.tags
            .where((tag) => attachedSet.contains(tag.id))
            .toList();
        final sections = tagsProvider.buildSections('', tagPool: tagPool);
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TagGroupedChipList(
            sections: sections,
            chipBuilder: (tag) => TagChip(
              tag: tag,
              onRemove: () => _tagSource.detach(tag.id!),
            ),
          ),
        );
      },
    );
  }

  Widget saveButton() {
    return IconButton(
      icon: const Icon(Icons.check),
      onPressed: () async {
        await _saveTemplate();
      },
    );
  }

  Widget deleteButton() {
    return IconButton(
      icon: const Icon(Icons.delete_rounded),
      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
      onPressed: _confirmDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.template != null) deleteButton(),
          saveButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Card.filled(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                            ),
                            child: TextField(
                              controller: _nameController,
                              maxLines: 1,
                              textCapitalization: TextCapitalization.words,
                              spellCheckConfiguration: SpellCheckConfiguration(
                                  spellCheckService:
                                      DefaultSpellCheckService()),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    AppLocalizations.of(context)!.titleHint,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildTagChips(),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _focusNode.requestFocus(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: EntryTextEditor(
                                      text: templateText,
                                      focusNode: _focusNode,
                                      textEditingController:
                                          _textEditingController,
                                      undoHistoryController: _undoController,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: EditToolbar(
              controller: _textEditingController,
              undoController: _undoController,
              focusNode: _focusNode,
              showTemplateButton: false,
              trailer: TemplateVariableButton(
                controller: _textEditingController,
                onAddTags: _openTagPicker,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
