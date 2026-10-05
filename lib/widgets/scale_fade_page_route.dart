// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const double _startScale = 0.85;
const Duration _duration = Duration(milliseconds: 200);

class ScaleFadePageRoute<T> extends MaterialPageRoute<T> {
  ScaleFadePageRoute({required super.builder})
      : super(allowSnapshotting: false);

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  Duration get transitionDuration => _duration;

  @override
  Duration get reverseTransitionDuration => _duration;

  @override
  void handleCommitBackGesture() {
    final gestureNavigator = navigator;
    if (gestureNavigator == null) return;
    final wasCurrent = isCurrent;
    if (wasCurrent) gestureNavigator.pop();
    final exit = controller;
    if (wasCurrent && exit != null && exit.isAnimating) {
      late final AnimationStatusListener onStatus;
      onStatus = (status) {
        exit.removeStatusListener(onStatus);
        gestureNavigator.didStopUserGesture();
      };
      exit.addStatusListener(onStatus);
    } else {
      gestureNavigator.didStopUserGesture();
    }
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return _BackGestureListener(
      route: this,
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: _startScale, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class _BackGestureListener extends StatefulWidget {
  const _BackGestureListener({required this.route, required this.child});

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_BackGestureListener> createState() => _BackGestureListenerState();
}

class _BackGestureListenerState extends State<_BackGestureListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent ||
        !widget.route.isCurrent ||
        !widget.route.popGestureEnabled) {
      return false;
    }
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) =>
      widget.route
          .handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);

  @override
  void handleCancelBackGesture() => widget.route.handleCancelBackGesture();

  @override
  void handleCommitBackGesture() => widget.route.handleCommitBackGesture();

  @override
  Widget build(BuildContext context) => widget.child;
}
