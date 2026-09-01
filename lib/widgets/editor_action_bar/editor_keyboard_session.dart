import 'dart:async';

import 'package:flutter/widgets.dart';

enum EditorFocusState {
  /// Never focused, or the user clicked away
  unfocused,

  /// Focused, on-screen keyboard up
  docked,

  /// Focused, on-screen keyboard has never appeared
  floating,

  /// Focused, keyboard was up and has since been dismissed
  dismissed,
}

/// Derives [state] from [focusNode] and the debounced keyboard-inset signal
class EditorKeyboardSession extends ChangeNotifier {
  static const dismissDebounceDuration = Duration(milliseconds: 80);

  final FocusNode focusNode;

  bool _dismissed = false;
  bool _everShown;
  bool _isUp;
  double _lastInset;
  Timer? _dismissDebounce;

  EditorKeyboardSession({required this.focusNode, double initialInset = 0})
      : _lastInset = initialInset,
        _everShown = initialInset > 0,
        _isUp = initialInset > 0 {
    focusNode.addListener(_handleFocusChanged);
  }

  EditorFocusState get state {
    if (!focusNode.hasFocus) return EditorFocusState.unfocused;
    if (_dismissed) return EditorFocusState.dismissed;
    return _everShown ? EditorFocusState.docked : EditorFocusState.floating;
  }

  bool get isEditing =>
      state == EditorFocusState.docked || state == EditorFocusState.floating;

  /// React to a new inset
  void noteKeyboardInset(double inset) {
    if (inset == _lastInset) return;
    final rising = inset > _lastInset;
    _lastInset = inset;
    if (rising) {
      _dismissDebounce?.cancel();
      _dismissDebounce = null;
      _isUp = true;
      // A rise clears a dismissal on its own. If the user switches keyboard it a new keyboard will appear
      final alreadyDocked = _everShown && !_dismissed;
      _everShown = true;
      _dismissed = false;
      if (!alreadyDocked) notifyListeners();
      return;
    }
    if (!_isUp || !focusNode.hasFocus) return;
    _dismissDebounce ??= Timer(dismissDebounceDuration, () {
      _dismissDebounce = null;
      _isUp = false;
      _setDismissed(true);
    });
  }

  void resume() {
    _dismissDebounce?.cancel();
    _dismissDebounce = null;
    _setDismissed(false);
  }

  void _setDismissed(bool dismissed) {
    if (dismissed == _dismissed) return;
    _dismissed = dismissed;
    notifyListeners();
  }

  void _handleFocusChanged() => notifyListeners();

  @override
  void dispose() {
    _dismissDebounce?.cancel();
    focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }
}

/// Scope to provide [EditorKeyboardSession] to the bar
class EditorKeyboardSessionScope
    extends InheritedNotifier<EditorKeyboardSession> {
  const EditorKeyboardSessionScope({
    super.key,
    required EditorKeyboardSession session,
    required super.child,
  }) : super(notifier: session);

  static EditorKeyboardSession? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EditorKeyboardSessionScope>()
      ?.notifier;
}
