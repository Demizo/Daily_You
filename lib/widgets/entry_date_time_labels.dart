// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/time_manager.dart';
import 'package:material_ui/material_ui.dart';

class EntryDateTimeLabels extends StatelessWidget {
  final DateTime dateTime;
  final Color? dateColor;
  final Color? timeColor;
  final VoidCallback? onDateTap;
  final VoidCallback? onTimeTap;

  const EntryDateTimeLabels({
    super.key,
    required this.dateTime,
    this.dateColor,
    this.timeColor,
    this.onDateTap,
    this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label(
            TimeManager.formatDateWithWeekday(dateTime, context),
            color: dateColor,
            fontWeight: FontWeight.bold,
            onTap: onDateTap,
          ),
          VerticalDivider(
            width: 2,
            indent: 8,
            endIndent: 8,
            thickness: 2,
            radius: BorderRadius.circular(4),
          ),
          _label(
            TimeManager.localizedTimeFormat(
                    context, TimeManager.currentLocale(context))
                .format(dateTime),
            color: timeColor,
            onTap: onTimeTap,
          ),
        ],
      ),
    );
  }

  Widget _label(
    String text, {
    required Color? color,
    FontWeight? fontWeight,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
