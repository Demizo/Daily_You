import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/markdown_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditToolbar extends StatelessWidget {
  const EditToolbar({
    super.key,
    required this.controller,
    required this.undoController,
    required this.focusNode,
    this.trailer,
  });

  final TextEditingController controller;
  final UndoHistoryController undoController;
  final FocusNode focusNode;
  final Widget? trailer;

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
            ValueListenableBuilder<UndoHistoryValue>(
                valueListenable: undoController,
                builder: (BuildContext context, UndoHistoryValue value,
                    Widget? child) {
                  return IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (configProvider.get(ConfigKey.useMarkdownToolbar))
                          VerticalDivider(
                            width: 0,
                            thickness: 2,
                          ),
                        SizedBox(
                          width: 8,
                        ),
                        IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => {undoController.undo()},
                            icon: Icon(
                              Icons.undo_rounded,
                              color: value.canUndo
                                  ? null
                                  : Theme.of(context).disabledColor,
                              size: 24,
                            )),
                        IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => {undoController.redo()},
                            icon: Icon(
                              Icons.redo_rounded,
                              color: value.canRedo
                                  ? null
                                  : Theme.of(context).disabledColor,
                              size: 24,
                            )),
                        if (trailer != null) trailer!
                      ],
                    ),
                  );
                })
          ],
        ),
      ],
    );
  }
}
