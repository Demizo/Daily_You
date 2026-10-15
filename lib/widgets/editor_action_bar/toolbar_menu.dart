// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' show SemanticsRole;

import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_menu_action.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class ToolbarMenu extends StatefulWidget {
  final Rect anchor;
  final List<ToolbarMenuAction> actions;
  final VoidCallback onClosed;

  const ToolbarMenu({
    super.key,
    required this.anchor,
    required this.actions,
    required this.onClosed,
  });

  @override
  State<ToolbarMenu> createState() => _ToolbarMenuState();
}

class _ToolbarMenuState extends State<ToolbarMenu>
    with SingleTickerProviderStateMixin {
  static const double _shadowRoom = 12.0;
  static const double _itemSpacing = 8.0;
  static const double _anchorOverlap = _shadowRoom - _itemSpacing;
  static const double _itemEntranceScale = 0.85;
  static const double _itemEntranceRise = 12.0;

  static const double _firstItemStart = 0.1;
  static const double _itemStartSpread = 0.3;
  static const double _itemShare = 0.6;

  late final AnimationController _controller;
  late final List<Animation<double>> _itemProgress;
  late final bool _navigatingWithKeyboard;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    final count = widget.actions.length;
    CurvedAnimation entrance(int stepsFromButton) {
      final start =
          _firstItemStart + _itemStartSpread * stepsFromButton / count;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, start + _itemShare, curve: Curves.easeOutBack),
        reverseCurve: Curves.linear,
      );
    }

    _itemProgress = [
      for (var index = 0; index < count; index++) entrance(count - 1 - index),
    ];
    _navigatingWithKeyboard =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reduceMotion ? Durations.short3 : Durations.medium2;
    _controller.reverseDuration =
        reduceMotion ? Durations.short2 : Durations.short3;
    if (!_closing && _controller.isDismissed) _controller.forward();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _controller.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    _close();
    return true;
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _controller.reverse().then((_) => widget.onClosed());
  }

  void _select(ToolbarMenuAction action) {
    if (_closing) return;
    _close();
    action.onSelected();
  }

  Widget _reveal(Animation<double> progress, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: _controller, child: child);
    }
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) => Opacity(
        opacity: (progress.value * 1.5).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - progress.value) * _itemEntranceRise),
          child: Transform.scale(
            scale:
                _itemEntranceScale + (1 - _itemEntranceScale) * progress.value,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TextFieldTapRegion(
            child: ModalBarrier(
              onDismiss: _close,
              semanticsLabel:
                  MaterialLocalizations.of(context).modalBarrierDismissLabel,
            ),
          ),
        ),
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _ToolbarMenuLayoutDelegate(
              anchor: widget.anchor,
              topInset: MediaQuery.paddingOf(context).top,
            ),
            child: TextFieldTapRegion(
              child: Semantics(
                role: SemanticsRole.menu,
                container: true,
                child: FocusScope(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(_shadowRoom),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: _itemSpacing,
                        children: [
                          for (final (index, action) in widget.actions.indexed)
                            _reveal(
                              _itemProgress[index],
                              _ToolbarMenuItem(
                                action: action,
                                autofocus: _navigatingWithKeyboard &&
                                    index == widget.actions.length - 1,
                                onSelected: () => _select(action),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect anchor;
  final double topInset;

  const _ToolbarMenuLayoutDelegate({
    required this.anchor,
    required this.topInset,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    const margin = DockMetrics.screenMargin;
    final maxWidth =
        (constraints.maxWidth - margin * 2).clamp(0.0, double.infinity);
    final maxHeight =
        (anchor.top + _ToolbarMenuState._anchorOverlap - topInset - margin)
            .clamp(0.0, constraints.maxHeight);
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const margin = DockMetrics.screenMargin;
    final left = (anchor.center.dx - childSize.width / 2)
        .clamp(margin, size.width - childSize.width - margin);
    return Offset(
        left, anchor.top + _ToolbarMenuState._anchorOverlap - childSize.height);
  }

  @override
  bool shouldRelayout(_ToolbarMenuLayoutDelegate oldDelegate) =>
      anchor != oldDelegate.anchor || topInset != oldDelegate.topInset;
}

class _ToolbarMenuItem extends StatefulWidget {
  final ToolbarMenuAction action;
  final bool autofocus;
  final VoidCallback onSelected;

  const _ToolbarMenuItem({
    required this.action,
    required this.autofocus,
    required this.onSelected,
  });

  @override
  State<_ToolbarMenuItem> createState() => _ToolbarMenuItemState();
}

class _ToolbarMenuItemState extends State<_ToolbarMenuItem> {
  static const double _minimumHeight = 56.0;
  static const double _restingCornerRadius = 20.0;
  static const double _pressedCornerRadius = _minimumHeight / 2;
  static const double _iconContainerSize = 40.0;
  static const double _restingIconContainerRadius = 14.0;
  static const double _focusRingWidth = 2.0;
  static const double _itemElevation = 3.0;

  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final morph = _pressed && !reduceMotion;
    final morphDuration = reduceMotion ? Duration.zero : Durations.short4;
    final emphasis = _pressed
        ? 0.24
        : (_hovered || _focused)
            ? 0.12
            : 0.0;

    final cornerRadius = BorderRadius.circular(
        morph ? _pressedCornerRadius : _restingCornerRadius);

    return Semantics(
      role: SemanticsRole.menuItem,
      button: true,
      child: AnimatedPhysicalModel(
        duration: morphDuration,
        curve: Curves.easeOutBack,
        shape: BoxShape.rectangle,
        clipBehavior: Clip.antiAlias,
        borderRadius: cornerRadius,
        elevation: _itemElevation,
        color: Color.lerp(
            colorScheme.primaryContainer, colorScheme.primary, emphasis)!,
        shadowColor: theme.shadowColor.withValues(alpha: 0.4),
        child: AnimatedContainer(
          duration: morphDuration,
          curve: Curves.easeOutBack,
          decoration: BoxDecoration(
            borderRadius: cornerRadius,
            border: Border.all(
                color: _focused
                    ? colorScheme.onPrimaryContainer
                    : Colors.transparent,
                width: _focusRingWidth),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              autofocus: widget.autofocus,
              onTap: widget.onSelected,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onHover: (value) => setState(() => _hovered = value),
              onFocusChange: (value) => setState(() => _focused = value),
              splashColor:
                  colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minHeight: _minimumHeight - _focusRingWidth * 2),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 20, 6),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: morphDuration,
                        curve: Curves.easeOutBack,
                        width: _iconContainerSize,
                        height: _iconContainerSize,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(morph
                              ? _iconContainerSize / 2
                              : _restingIconContainerRadius),
                        ),
                        child: Icon(widget.action.icon,
                            color: colorScheme.onPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.action.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
