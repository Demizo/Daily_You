import 'dart:async';

import 'package:flutter/widgets.dart';

class ToolbarFocusRestorer {
  /// Delay to restore focus after focus shifts back from a system prompt
  static const Duration _keyboardReconnectDelay = Duration(milliseconds: 300);

  final FocusNode _focusNode;

  /// If dismissed, remove editor focus on any action
  final bool Function() isDismissed;

  final VoidCallback? onIdle;

  final VoidCallback? onReconnect;

  int _pendingActions = 0;
  bool _disposed = false;

  ToolbarFocusRestorer(this._focusNode,
      {required this.isDismissed, this.onIdle, this.onReconnect});

  bool get isRunningAction => _pendingActions > 0;

  void dispose() => _disposed = true;

  Future<void> run(
    FutureOr<void> Function() action, {
    bool claimsFocus = true,
    bool reconnectsKeyboard = false,
  }) async {
    if (isDismissed()) {
      _focusNode.unfocus(disposition: UnfocusDisposition.scope);
      await action();
      return;
    }

    if (!claimsFocus && !_focusNode.hasFocus) {
      await action();
      return;
    }

    _pendingActions++;
    try {
      await action();
    } finally {
      if (!_disposed) {
        if (reconnectsKeyboard && _focusNode.hasFocus) {
          _focusNode.unfocus();
          await Future<void>.delayed(_keyboardReconnectDelay);
          onReconnect?.call();
        }
        if (!_disposed) _focusNode.requestFocus();
      }
      _pendingActions--;
      if (_pendingActions == 0 && !_disposed) {
        // Wait for requestFocus microtask to complete
        await Future<void>.microtask(() {});
        if (_pendingActions == 0 && !_disposed) onIdle?.call();
      }
    }
  }
}
