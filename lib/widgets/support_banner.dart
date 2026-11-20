// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/app_distribution.dart';
import 'package:daily_you/utils/support_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportBanner extends StatelessWidget {
  final ConfigProvider configProvider;

  const SupportBanner({super.key, required this.configProvider});

  static DateTime? mostRecentReminderDate(DateTime now) {
    final candidates = [
      DateTime(now.year, 8, 6),
      DateTime(now.year, 12, 6),
      DateTime(now.year - 1, 12, 6),
    ];
    final past = candidates.where((d) => !d.isAfter(now)).toList()..sort();
    return past.isEmpty ? null : past.last;
  }

  static bool shouldShowBanner({
    required int entryCount,
    required String? lastDismissedIso,
    DateTime? now,
  }) {
    if (entryCount < 30) return false;

    final today = now ?? DateTime.now();
    final reminderDate = mostRecentReminderDate(today);
    if (reminderDate == null) return false;

    if (lastDismissedIso == null || lastDismissedIso.isEmpty) return true;

    final dismissed = DateTime.tryParse(lastDismissedIso);
    if (dismissed == null) return true;

    return reminderDate.isAfter(dismissed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = isPlayStoreBuild
        ? l10n.supportBannerOpenSourceTitle
        : l10n.settingsMadeWithLove;
    final actionLabel = isPlayStoreBuild
        ? l10n.supportBannerFeedbackPrompt
        : l10n.settingsConsiderSupporting;
    final separator = isPlayStoreBuild ? '\n' : ' ';
    final titleStyle =
        textTheme.titleSmall?.copyWith(color: colorScheme.onSurface);
    final actionStyle = titleStyle?.copyWith(
      color: colorScheme.primary,
      decorationColor: colorScheme.primary,
    );

    return Card.filled(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            launchUrl(supportPageUri, mode: LaunchMode.externalApplication),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 28),
                      child: Text.rich(
                        TextSpan(
                          style: titleStyle,
                          children: [
                            TextSpan(text: title),
                            TextSpan(text: separator),
                            TextSpan(text: actionLabel, style: actionStyle),
                            const TextSpan(text: ' '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                onPressed: () => configProvider.set(
                  Settings.lastDismissedSupportBannerDate,
                  DateTime.now().toIso8601String(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
