// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_background.dart';
import 'package:daily_you/pages/onboarding/onboarding_footer.dart';
import 'package:daily_you/pages/onboarding/onboarding_progress_bar.dart';
import 'package:daily_you/pages/onboarding/onboarding_scope.dart';
import 'package:daily_you/pages/onboarding/onboarding_step.dart';
import 'package:daily_you/pages/onboarding/onboarding_step_layout.dart';
import 'package:daily_you/pages/onboarding/reminders_step.dart';
import 'package:daily_you/pages/onboarding/import_step.dart';
import 'package:daily_you/pages/onboarding/storage_step.dart';
import 'package:daily_you/pages/onboarding/welcome_step.dart';
import 'package:daily_you/utils/onboarding_status.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.nextPage});

  final Widget nextPage;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  static const Duration _pageDuration = Duration(milliseconds: 500);

  final List<OnboardingStep> _steps =
      OnboardingStep.sequence(includesReminders: Platform.isAndroid);
  final PageController _pageController = PageController();
  final ValueNotifier<double> _position = ValueNotifier(0);
  final ValueNotifier<bool> _transitioning = ValueNotifier(false);
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));
  bool _animationsDisabled = false;
  int _targetPage = 0;
  bool _navigating = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_syncPosition);
    _transitioning.addListener(_syncAmbient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsDisabled = MediaQuery.disableAnimationsOf(context);
    _syncAmbient();
  }

  void _syncAmbient() {
    if (_animationsDisabled || _transitioning.value) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _position.dispose();
    _transitioning.dispose();
    _ambient.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      _transitioning.value = true;
    } else if (notification is ScrollEndNotification) {
      _transitioning.value = false;
    }
    return false;
  }

  void _syncPosition() {
    if (_pageController.hasClients && _pageController.position.haveDimensions) {
      _position.value = _pageController.page!;
    }
  }

  Future<void> _goToPage(int index) async {
    if (_navigating || _finishing || index < 0 || index >= _steps.length) {
      return;
    }
    _navigating = true;
    _targetPage = index;
    try {
      await _pageController.animateToPage(index,
          duration: _pageDuration, curve: Curves.easeInOutCubicEmphasized);
    } finally {
      _navigating = false;
    }
  }

  void _goBack() {
    if (_finishing) return;
    if (_targetPage == 0) {
      SystemNavigator.pop();
    } else {
      _goToPage(_targetPage - 1);
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await OnboardingStatus.complete();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => widget.nextPage,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  Widget _buildStep(OnboardingStep step, int index) => switch (step) {
        OnboardingStep.welcome => WelcomeStep(index: index),
        OnboardingStep.importData => ImportStep(index: index),
        OnboardingStep.reminders => RemindersStep(index: index),
        OnboardingStep.storage => StorageStep(index: index),
      };

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 12, 0),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: OnboardingStepLayout.maxWidth),
          child: Row(
            children: [
              Expanded(
                child: OnboardingProgressBar(
                  count: _steps.length,
                  position: _position,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: OnboardingScope(
            ambient: _ambient,
            position: _position,
            transitioning: _transitioning,
            onFinish: _finish,
            child: Column(
              children: [
                _buildTopBar(l10n),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Positioned.fill(
                          top: OnboardingStepLayout.verticalPadding +
                              OnboardingStepLayout.illustrationExtent(
                                  constraints.maxHeight),
                          child: OnboardingBackground(
                              ambient: _ambient, position: _position),
                        ),
                        NotificationListener<ScrollNotification>(
                          onNotification: _onScrollNotification,
                          child: PageView(
                            controller: _pageController,
                            allowImplicitScrolling: true,
                            scrollCacheExtent:
                                ScrollCacheExtent.viewport(_steps.length - 1.0),
                            onPageChanged: (index) => _targetPage = index,
                            children: [
                              for (final (index, step) in _steps.indexed)
                                _buildStep(step, index),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                OnboardingFooter(
                  stepCount: _steps.length,
                  position: _position,
                  onNext: () => _goToPage(_targetPage + 1),
                  onFinish: _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
