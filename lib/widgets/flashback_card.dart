// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/widgets/attachment_grid.dart';
import 'package:daily_you/widgets/expressive_carousel.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:material_ui/material_ui.dart';

const _cardInset = 14.0;
const _countBadgeSize = 20.0;
const _layerIsolationOpacity = 0.99;

class FlashbackCard extends StatelessWidget {
  const FlashbackCard({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final attachmentsProvider = EntryAttachmentsProvider.instance;
    final hideImages =
        ConfigProvider.instance.get(Settings.hideImagesInFlashbacks);
    final theme = Theme.of(context);
    final text = entries.first.text;

    final coverImages = hideImages
        ? <EntryAttachment>[]
        : entries
            .map((e) => attachmentsProvider
                .getForEntry(e)
                .where((attachment) => attachment.type.isVisual)
                .firstOrNull)
            .whereType<EntryAttachment>()
            .take(4)
            .toList();

    final hasImages = coverImages.isNotEmpty;
    final showCount = entries.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        hasImages
            ? AttachmentGrid(attachments: coverImages)
            : ClipRect(
                clipBehavior: Clip.hardEdge,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.60, 0.75],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Padding(
                    padding: const EdgeInsets.all(_cardInset),
                    child: Wrap(children: [
                      IgnorePointer(
                          child: SizedBox(
                        width: double.maxFinite,
                        child: Padding(
                            padding: EdgeInsets.only(
                                top: showCount ? _countBadgeSize + 4 : 0),
                            child: (text.isNotEmpty)
                                ? ScaledMarkdown(
                                    data: text,
                                    maxCharacters: 120,
                                    scaleFactor: 0.9,
                                    compact: true,
                                  )
                                : Text(
                                    AppLocalizations.of(
                                      context,
                                    )!
                                        .writeSomethingHint,
                                    style: TextStyle(
                                      color: theme.disabledColor,
                                      fontSize: 16,
                                    ),
                                  )),
                      ))
                    ]),
                  ),
                ),
              ),
        if (hasImages)
          Container(
            color: Colors.black.withValues(alpha: 0.30),
          ),
        PositionedDirectional(
          start: _cardInset,
          end: _cardInset,
          bottom: _cardInset,
          child: CarouselItemFade(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  color: hasImages ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if (showCount)
          PositionedDirectional(
            top: _cardInset,
            start: _cardInset,
            child: CarouselItemFade(
              // The Opacity widget (< 1.0) forces Flutter to composite this entire
              // container in an isolated layer. This ensures the BlendMode.dstOut
              // only punches a hole through the white circle, not the main images underneath
              child: Opacity(
                opacity: _layerIsolationOpacity,
                child: Container(
                  height: _countBadgeSize,
                  width: _countBadgeSize,
                  decoration: BoxDecoration(
                    color:
                        hasImages ? Colors.white : theme.colorScheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      entries.length < 99 ? '${entries.length}' : '99',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()..blendMode = BlendMode.dstOut,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
