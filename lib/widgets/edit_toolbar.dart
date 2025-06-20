import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/markdown_toolbar.dart';
import 'package:daily_you/widgets/template_select.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditToolbar extends StatelessWidget {
  const EditToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showTemplatesButton,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showTemplatesButton;

  void _showTemplateSelectPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TemplateSelect(
          onTemplatesSelected: (Template template) {
            if (controller.text.isNotEmpty) {
              controller.text += "\n${template.text ?? ""}";
            } else {
              controller.text = template.text ?? "";
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  configProvider.get(ConfigKey.useMarkdownToolbar)
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 24,
                ),
                onPressed: () async {
                  configProvider.set(ConfigKey.useMarkdownToolbar,
                      !configProvider.get(ConfigKey.useMarkdownToolbar));
                },
              ),
            ),
            if (configProvider.get(ConfigKey.useMarkdownToolbar))
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: MarkdownToolbar(
                    controller: controller,
                    focusNode: focusNode,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => {},
                    icon: Icon(
                      Icons.undo_rounded,
                      size: 24,
                    )),
                IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => {},
                    icon: Icon(
                      Icons.redo_rounded,
                      size: 24,
                    )),
                if (showTemplatesButton)
                  IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showTemplateSelectPopup(context),
                      icon: Icon(
                        Icons.note_add_rounded,
                        size: 24,
                      )),
              ],
            )
          ],
        ),
      ],
    );
  }
}
