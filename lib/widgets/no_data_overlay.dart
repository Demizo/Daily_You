// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class NoDataOverlay extends StatelessWidget {
  const NoDataOverlay({
    super.key,
    required this.hasData,
    required this.child,
    this.fontSize = 22,
  });

  static const double _emptyOpacity = 0.3;

  final bool hasData;
  final Widget child;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: hasData ? 1.0 : _emptyOpacity, child: child),
          if (!hasData)
            Text(
              AppLocalizations.of(context)!.statisticsNotEnoughData,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).disabledColor,
              ),
            ),
        ],
      );
}
