// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_illustrations.dart';
import 'package:daily_you/pages/onboarding/onboarding_scope.dart';
import 'package:daily_you/pages/onboarding/onboarding_step_layout.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:daily_you/widgets/connected_button_group.dart';
import 'package:daily_you/widgets/mood_scale_setting.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class WelcomeStep extends StatelessWidget {
  static const _themes = ['system', 'light', 'dark'];
  static const _themeIcons = [
    Icons.brightness_auto_rounded,
    Icons.light_mode_rounded,
    Icons.dark_mode_rounded,
  ];

  const WelcomeStep({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final storedTheme = context.watch<ConfigProvider>().get(Settings.theme);
    final selectedTheme =
        _themes.indexOf(storedTheme == 'amoled' ? 'dark' : storedTheme);
    final levels = context.watch<MoodScaleProvider>().levels;

    return OnboardingStepLayout(
      index: index,
      illustration: WelcomeIllustration(
          ambient: OnboardingScope.of(context).ambient, levels: levels),
      title: l10n.onboardingWelcomeTitle,
      description: l10n.onboardingWelcomeDescription,
      children: [
        ConnectedButtonGroup(
          labels: [l10n.themeSystem, l10n.themeLight, l10n.themeDark],
          icons: _themeIcons,
          restingColor: theme.colorScheme.surfaceContainerHigh,
          expanded: true,
          selectedIndex: selectedTheme < 0 ? 0 : selectedTheme,
          onSelectionChanged: (selected) =>
              context.read<ThemeModeProvider>().setTheme(_themes[selected]),
        ),
        const SizedBox(height: 20),
        Card.filled(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => MoodScaleSetting.edit(context,
                title: l10n.onboardingMoodsCustomize),
            child: Column(
              children: [
                const IgnorePointer(child: MoodScaleSetting()),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      Text(
                        l10n.onboardingMoodsCustomize,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
