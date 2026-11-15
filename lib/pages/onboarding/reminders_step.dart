// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/pages/onboarding/onboarding_illustrations.dart';
import 'package:daily_you/pages/onboarding/onboarding_step_layout.dart';
import 'package:daily_you/pages/onboarding/onboarding_tile.dart';
import 'package:daily_you/pages/settings/notification_settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class RemindersStep extends StatelessWidget {
  const RemindersStep({super.key, required this.index});

  final int index;

  Future<void> _setReminders(BuildContext context, bool enabled) async {
    final configProvider = ConfigProvider.instance;
    await NotificationSettings.setDailyReminders(context, enabled);
    if (configProvider.get(Settings.dailyReminders) != enabled) return;

    await (enabled
        ? NotificationManager.instance.startOnThisDayNotifications()
        : NotificationManager.instance.stopOnThisDayNotifications());
    await configProvider.set(Settings.onThisDayNotifications, enabled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled =
        context.watch<ConfigProvider>().get(Settings.dailyReminders);

    return OnboardingStepLayout(
      index: index,
      illustration:
          const OnboardingIllustration(icon: Icons.notifications_rounded),
      title: l10n.onboardingRemindersTitle,
      description: l10n.onboardingRemindersDescription,
      children: [
        OnboardingTile(
          icon: Icons.notifications_active_rounded,
          title: l10n.settingsDailyReminderTitle,
          selected: enabled,
          trailing: Switch(
              value: enabled,
              onChanged: (value) => _setReminders(context, value)),
          onTap: () => _setReminders(context, !enabled),
        ),
        OnboardingReveal(
          visible: enabled,
          child: OnboardingTile(
            icon: Icons.schedule_rounded,
            title: NotificationSettings.dailyReminderTime(context),
            compact: true,
            trailing: OnboardingTile.editIcon,
            onTap: () => NotificationSettings.selectReminderTime(context),
          ),
        ),
      ],
    );
  }
}
