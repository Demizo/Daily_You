// Logdaloop: Instagram-style card for the Feed tab.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:material_ui/material_ui.dart';

/// A full-width feed card: date + mood header, swipeable photos and the
/// entry text collapsed to [collapsedLines] lines with a "more" toggle.
class FeedCard extends StatefulWidget {
  const FeedCard({
    super.key,
    required this.entry,
    required this.images,
    required this.onTap,
  });

  final Entry entry;

  /// Image attachments of [entry], in display order.
  final List<EntryAttachment> images;

  final VoidCallback onTap;

  static const int collapsedLines = 4;

  /// Width the photos are decoded at; large enough for a full-width phone
  /// image while still going through the app's resized-image cache.
  static const int photoCacheWidth = 1080;

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool _expanded = false;
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme),
            if (widget.images.isNotEmpty) _buildPhotos(theme),
            _buildText(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              TimeManager.formatDate(widget.entry.timeCreate, context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          MoodIcon(moodValue: widget.entry.mood, size: 24),
        ],
      ),
    );
  }

  Widget _buildPhotos(ThemeData theme) {
    final images = widget.images;
    final shownIndex = _photoIndex.clamp(0, images.length - 1);
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Stack(
          children: [
            Positioned.fill(
              child: images.length == 1
                  ? _photo(images.first)
                  : PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) =>
                          setState(() => _photoIndex = index),
                      itemBuilder: (context, index) => _photo(images[index]),
                    ),
            ),
            if (images.length > 1) ...[
              PositionedDirectional(
                top: 10,
                end: 10,
                child: _PhotoCounter(
                  label: '${shownIndex + 1}/${images.length}',
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: _PageDots(count: images.length, index: shownIndex),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photo(EntryAttachment attachment) => LocalImageLoader(
        key: ValueKey(attachment.filePath),
        imagePath: attachment.filePath,
        cacheSize: FeedCard.photoCacheWidth,
      );

  Widget _buildText(BuildContext context, ThemeData theme) {
    final text = widget.entry.text.trim();
    const padding = EdgeInsets.fromLTRB(16, 10, 16, 14);

    if (text.isEmpty) {
      // Photo-only entries need no placeholder; text-less, photo-less ones do.
      if (widget.images.isNotEmpty) return const SizedBox(height: 4);
      return Padding(
        padding: padding,
        child: Text(
          AppLocalizations.of(context)!.writeSomethingHint,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.disabledColor),
        ),
      );
    }

    if (_expanded) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Taps go to the card (opens the entry), like the other cards.
            IgnorePointer(child: ScaledMarkdown(data: text)),
            _toggle(theme, feedLessLabel,
                () => setState(() => _expanded = false)),
          ],
        ),
      );
    }

    final plain = feedPlainText(text);
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return Padding(
      padding: padding,
      child: LayoutBuilder(builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: plain, style: style),
          maxLines: FeedCard.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        // Short entries fit, so show them with their formatting intact.
        if (!overflows) {
          return IgnorePointer(child: ScaledMarkdown(data: text));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plain,
              maxLines: FeedCard.collapsedLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
            _toggle(theme, feedMoreLabel,
                () => setState(() => _expanded = true)),
          ],
        );
      }),
    );
  }

  Widget _toggle(ThemeData theme, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2, right: 24),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Logdaloop-only strings, kept out of the upstream .arb files on purpose.
const String feedMoreLabel = 'more';
const String feedLessLabel = 'less';

/// Strips common markdown syntax so a collapsed preview reads as plain text.
String feedPlainText(String markdown) {
  var text = markdown;
  // Images and links: drop images, keep link text.
  text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
  text = text.replaceAllMapped(
      RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1) ?? '');
  // Horizontal rules.
  text = text.replaceAll(RegExp(r'^\s*([-*_]\s*){3,}$', multiLine: true), '');
  // Line prefixes: headings, quotes, task boxes, bullets, numbers.
  text = text.replaceAll(
      RegExp(r'^\s{0,3}(#{1,6}\s+|>\s?|[-*+]\s+\[[ xX]\]\s+|[-*+]\s+|\d+[.)]\s+)',
          multiLine: true),
      '');
  // Code fences and inline code / strikethrough / highlight markers.
  text = text.replaceAll(RegExp(r'^```.*$', multiLine: true), '');
  text = text.replaceAll(RegExp(r'`|~~|=='), '');
  // Emphasis markers next to words (keeps snake_case and "2 * 3").
  text = text.replaceAll(
      RegExp(r'(?<!\w)[*_]+(?=\S)|(?<=\S)[*_]+(?!\w)'), '');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

class _PhotoCounter extends StatelessWidget {
  const _PhotoCounter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 8 : 6,
            height: i == index ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: i == index ? 0.95 : 0.55),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
          ),
      ],
    );
  }
}
