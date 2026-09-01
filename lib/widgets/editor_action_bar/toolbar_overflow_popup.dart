import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_entry.dart';
import 'package:flutter/material.dart';

class ToolbarOverflowPopup {
  static const double _horizontalPadding = 6.0;
  static const double _verticalPadding = 4.0;
  static const double _cornerRadius = 28.0;
  static const double _elevation = 4.0;

  OverlayEntry? _overlayEntry;

  void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void show(BuildContext buttonContext, List<ToolbarEntry> entries) {
    dismiss();

    final overlayState = Navigator.of(buttonContext).overlay!;
    final overlayBox = overlayState.context.findRenderObject()! as RenderBox;
    final button = buttonContext.findRenderObject()! as RenderBox;
    final buttonPosition =
        button.localToGlobal(Offset.zero, ancestor: overlayBox);

    final screenSize = MediaQuery.sizeOf(buttonContext);
    const margin = DockMetrics.screenMargin;
    final contentWidth =
        entries.fold(_horizontalPadding * 2, (sum, entry) => sum + entry.width);
    final width = contentWidth.clamp(0.0, screenSize.width - margin * 2);
    final left =
        buttonPosition.dx.clamp(margin, screenSize.width - width - margin);
    final theme = Theme.of(buttonContext);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: TextFieldTapRegion(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
              ),
            ),
          ),
          Positioned(
            left: left,
            bottom: screenSize.height - buttonPosition.dy,
            width: width,
            child: TextFieldTapRegion(
              child: Material(
                color: Colors.transparent,
                child: Card(
                  elevation: _elevation,
                  color: theme.colorScheme.surfaceContainerHigh,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_cornerRadius)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _horizontalPadding,
                        vertical: _verticalPadding),
                    child: IconTheme.merge(
                      data: const IconThemeData(opacity: 1.0),
                      child: IntrinsicHeight(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final entry in entries)
                                entry.build(overlayContext, dismiss),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(_overlayEntry!);
  }
}
