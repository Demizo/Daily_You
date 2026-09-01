import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/editor_keyboard_session.dart';
import 'package:flutter/material.dart';

class EditorActionBarOverlay extends StatefulWidget {
  final Widget body;
  final EditorActionBar actionBar;
  final double keyboardInset;

  const EditorActionBarOverlay({
    super.key,
    required this.body,
    required this.actionBar,
    required this.keyboardInset,
  });

  /// Must be used outside of the Scaffold hold this overlay. The Scaffold body zeros the bottom inset
  static double keyboardInsetOf(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom;

  @override
  State<EditorActionBarOverlay> createState() => _EditorActionBarOverlayState();
}

class _EditorActionBarOverlayState extends State<EditorActionBarOverlay>
    with SingleTickerProviderStateMixin {
  // Android's InsetsController animation curves
  static const _showCurve = Cubic(0.0, 0.0, 0.2, 1.0);
  static const _hideCurve = Cubic(0.4, 0.0, 1.0, 1.0);
  static const _imeAnimationDuration = Duration(milliseconds: 200);

  late final AnimationController _dockController;
  late EditorKeyboardSession _session;

  late bool _docked;

  late double _lastInset;

  @override
  void initState() {
    super.initState();
    _docked = widget.keyboardInset > 0;
    _lastInset = widget.keyboardInset;
    _dockController =
        AnimationController(vsync: this, value: _docked ? 1.0 : 0.0);
    _session = EditorKeyboardSession(
        focusNode: widget.actionBar.focusNode,
        initialInset: widget.keyboardInset);
    widget.actionBar.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!widget.actionBar.focusNode.hasFocus && _docked) _setDocked(false);
  }

  void _setDocked(bool docked) {
    if (docked == _docked) return;
    _docked = docked;
    _dockController.animateTo(docked ? 1.0 : 0.0,
        duration: _imeAnimationDuration,
        curve: docked ? _showCurve : _hideCurve);
  }

  @override
  void didUpdateWidget(covariant EditorActionBarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionBar.focusNode != widget.actionBar.focusNode) {
      oldWidget.actionBar.focusNode.removeListener(_handleFocusChange);
      widget.actionBar.focusNode.addListener(_handleFocusChange);
      _session.dispose();
      _session = EditorKeyboardSession(
          focusNode: widget.actionBar.focusNode,
          initialInset: widget.keyboardInset);
    }
    // EditorKeyboardSession decides what's a real dismissal
    // This only morphs the bar's shape based on direction
    final inset = widget.keyboardInset;
    _session.noteKeyboardInset(inset);
    if (inset > _lastInset) {
      _setDocked(true);
    } else if (inset < _lastInset &&
        _dockController.status != AnimationStatus.forward) {
      _setDocked(false);
    }
    _lastInset = inset;
  }

  @override
  void dispose() {
    widget.actionBar.focusNode.removeListener(_handleFocusChange);
    _session.dispose();
    _dockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(viewInsets: EdgeInsets.only(bottom: widget.keyboardInset)),
      child: EditorKeyboardSessionScope(
        session: _session,
        child: DockProgressScope(
          progress: _dockController,
          child: Stack(
            children: [
              Positioned.fill(child: widget.body),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TextFieldTapRegion(child: widget.actionBar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
