import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
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
    return Card.filled(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0, bottom: 4.0),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              Icons.volunteer_activism_rounded,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text:
                        '${AppLocalizations.of(context)!.settingsMadeWithLove} ${AppLocalizations.of(context)!.settingsConsiderSupporting}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ]),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              onPressed: () async {
                await launchUrl(
                  Uri(
                    scheme: 'https',
                    host: 'github.com',
                    path: '/Demizo/Daily_You',
                    queryParameters: {'tab': 'readme-ov-file'},
                    fragment: 'support-the-app',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              onPressed: () async {
                await configProvider.set(
                  ConfigKey.lastDismissedSupportBannerDate,
                  DateTime.now().toIso8601String(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
