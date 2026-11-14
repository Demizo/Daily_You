// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/entry_semantics_label.dart';
import 'package:daily_you/widgets/bottom_fade.dart';
import 'package:daily_you/widgets/entry_card_header_row.dart';
import 'package:daily_you/widgets/attachment_grid.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/models/entry.dart';

const double entryCardCornerRadius = 12;
const double entryCardMargin = 4;
const double galleryHorizontalPadding = 2;

class EntryCardWidget extends StatelessWidget {
  const EntryCardWidget(
      {super.key,
      this.title,
      required this.entry,
      required this.attachments,
      this.hideImage = false});

  final Entry entry;
  final String? title;
  final List<EntryAttachment> attachments;
  final bool hideImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = TimeManager.formatDate(entry.timeCreate, context);
    final cardTitle = title ?? time;
    return Semantics(
        label: entrySemanticsLabel(context, entry, cardTitle),
        excludeSemantics: true,
        child: Card.filled(
          margin: const EdgeInsets.all(entryCardMargin),
          color: Theme.of(context).colorScheme.surfaceContainer,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ClipRRect(
                  clipBehavior: Clip.hardEdge,
                  borderRadius: BorderRadius.circular(entryCardCornerRadius),
                  child: (attachments.isNotEmpty && !hideImage)
                      ? AttachmentGrid(attachments: attachments)
                      : (entry.text.isNotEmpty)
                          ? BottomFade(
                              color: theme.colorScheme.surfaceContainer,
                              start: 0.85,
                              end: 1.0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Wrap(children: [
                                  IgnorePointer(
                                      child: SizedBox(
                                    width: double.maxFinite,
                                    child: ScaledMarkdown(
                                      data: entry.text,
                                      maxCharacters: 250,
                                      scaleFactor: 0.95,
                                    ),
                                  ))
                                ]),
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: AlignmentDirectional.topStart,
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .writeSomethingHint,
                                  style: TextStyle(
                                      color: theme.disabledColor, fontSize: 16),
                                ),
                              ),
                            ),
                ),
              ),
              EntryCardHeaderRow(
                entry: entry,
                title: cardTitle,
                titleStyle: TextStyle(
                    color: theme.textTheme.labelSmall?.color,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ));
  }
}
