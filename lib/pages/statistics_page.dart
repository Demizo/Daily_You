// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/layouts/window_size_class.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/pages/stats_subject_page.dart';
import 'package:daily_you/pages/writing_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/stats_layout_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/stats/streaks.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/content_width_limit.dart';
import 'package:daily_you/widgets/mood_tile.dart';
import 'package:daily_you/widgets/reorderable_tile_grid.dart';
import 'package:daily_you/widgets/sliver_stats_range_header.dart';
import 'package:daily_you/widgets/stat_tile.dart';
import 'package:daily_you/widgets/streak_tile.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/tag_tile.dart';
import 'package:daily_you/widgets/writing_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with AutomaticKeepAliveClientMixin {
  bool _isEditing = false;
  List<Entry>? _summarizedEntries;
  late WritingSummary _writingSummary;

  Object? _tileSummaryInputs;
  late MoodSummary _moodSummary;
  late Map<int, TagTileSummary> _tagSummaries;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) _isEditing = false;
  }

  WritingSummary _writingSummaryOf(List<Entry> entries) {
    if (!identical(entries, _summarizedEntries)) {
      _summarizedEntries = entries;
      _writingSummary = writingSummary(entries, StatsRange.allTime);
    }
    return _writingSummary;
  }

  void _refreshTileSummaries(
    List<Entry> entries,
    TagsProvider tagsProvider,
    List<int> pinnedTagIds,
    StatsRange range,
  ) {
    final inputs = (
      entries,
      tagsProvider.entryTags,
      tagsProvider.tags,
      pinnedTagIds,
      range,
    );
    if (inputs == _tileSummaryInputs) return;
    _tileSummaryInputs = inputs;
    _moodSummary = moodSummary(entries, range);
    _tagSummaries = tagTileSummaries(
      entries,
      tagsProvider.entryTags,
      tagsProvider.tags,
      pinnedTagIds,
      range,
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _replacePinned(List<int> tagIds) {
    context.read<StatsLayoutProvider>().replace(tagIds);
  }

  Future<void> _addTag() async {
    final layoutProvider = context.read<StatsLayoutProvider>();
    final tag = await showAppDialog<Tag>(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.selectSingle,
        excludedTagIds: layoutProvider.pinnedTagIds,
      ),
    );
    if (tag == null) return;
    layoutProvider.replace([...layoutProvider.pinnedTagIds, tag.id!]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final entries = context.watch<EntriesProvider>().entries;
    final tagsProvider = context.watch<TagsProvider>();
    final pinnedTagIds = context.watch<StatsLayoutProvider>().pinnedTagIds;
    final statsRange = context
        .select<ConfigProvider, StatsRange>((config) => config.statsRange);
    _refreshTileSummaries(entries, tagsProvider, pinnedTagIds, statsRange);
    final streaks = calculateStreaks(entries);
    final tagById = {for (final tag in tagsProvider.tags) tag.id: tag};
    final pinnedTags = [
      for (final tagId in pinnedTagIds)
        if (tagById[tagId] case final tag?) tag,
    ];
    final canAddTag = tagsProvider.tags.length > pinnedTags.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidthLimit(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _TopRow(
                streak: streaks.current,
                summary: _writingSummaryOf(entries),
                onTap: () => _push(const WritingPage()),
              ),
            ),
          ),
        ),
        SliverStatsRangeHeader(statsRange: statsRange),
        SliverToBoxAdapter(
          child: ContentWidthLimit(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: MoodTile(
                summary: _moodSummary,
                onTap: () => _push(const StatsSubjectPage()),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ContentWidthLimit(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ReorderableTileGrid(
                gridDelegate: StatTileGrid.gridDelegateOf(context),
                isEditing: _isEditing,
                onEditStart: () => setState(() => _isEditing = true),
                onReorder: (oldIndex, newIndex) {
                  final reordered = [for (final tag in pinnedTags) tag.id!];
                  reordered.insert(newIndex, reordered.removeAt(oldIndex));
                  _replacePinned(reordered);
                },
                children: [
                  for (final tag in pinnedTags)
                    _PinnedTagTile(
                      key: ValueKey(tag.id),
                      tag: tag,
                      summary: _tagSummaries[tag.id]!,
                      isEditing: _isEditing,
                      onTap: () => _push(StatsSubjectPage(tag: tag)),
                      onRemove: () => _replacePinned([
                        for (final pinned in pinnedTags)
                          if (pinned != tag) pinned.id!,
                      ]),
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ContentWidthLimit(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 32),
              child: _CustomizeBar(
                isEditing: _isEditing,
                onCustomize: () => setState(() => _isEditing = true),
                onAdd: canAddTag ? _addTag : null,
                onDone: () => setState(() => _isEditing = false),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PinnedTagTile extends StatelessWidget {
  const _PinnedTagTile({
    super.key,
    required this.tag,
    required this.summary,
    required this.isEditing,
    required this.onTap,
    required this.onRemove,
  });

  final Tag tag;
  final TagTileSummary summary;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: TagTile(
          tag: tag,
          summary: summary,
          onTap: isEditing ? null : onTap,
        ),
      ),
      if (isEditing)
        PositionedDirectional(
          top: 8,
          end: 8,
          child: IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: const Icon(Icons.close_rounded),
            onPressed: onRemove,
          ),
        ),
    ]);
  }
}

class _CustomizeBar extends StatelessWidget {
  const _CustomizeBar({
    required this.isEditing,
    required this.onCustomize,
    required this.onAdd,
    required this.onDone,
  });

  static const double _buttonHeight = 56;
  static const double _gap = 8;
  static const double _labelGap = 12;
  static const double _iconSize = 24;
  static const Duration _duration = Duration(milliseconds: 300);
  static const Curve _curve = Curves.easeOutBack;
  static const Duration _closeDuration = Duration(milliseconds: 400);
  static const Curve _closeCurve = Cubic(0.2, 0.9, 0.3, 1.6);
  static const Duration _labelDuration = Duration(milliseconds: 200);
  static const Duration _labelExitDuration = Duration(milliseconds: 100);

  final bool isEditing;
  final VoidCallback onCustomize;
  final VoidCallback? onAdd;
  final VoidCallback onDone;

  Widget _doneButton() => Padding(
        key: const ValueKey('done'),
        padding: const EdgeInsetsDirectional.only(start: _gap),
        child: FilledButton(
          style: FilledButton.styleFrom(
            fixedSize: const Size.square(_buttonHeight),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            visualDensity: VisualDensity.standard,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onDone,
          child: const Icon(Icons.check_rounded, size: _iconSize),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Flexible(
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            fixedSize: const Size.fromHeight(_buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            visualDensity: VisualDensity.standard,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
          ),
          onPressed: isEditing ? onAdd : onCustomize,
          child: AnimatedSize(
            duration: isEditing ? _duration : _closeDuration,
            curve: isEditing ? _curve : _closeCurve,
            clipBehavior: Clip.none,
            child: AnimatedSwitcher(
              duration: _labelDuration,
              reverseDuration: _labelExitDuration,
              switchInCurve: const Interval(0.4, 1),
              child: Row(
                key: ValueKey(isEditing),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEditing ? Icons.add_rounded : Icons.tune_rounded,
                    size: _iconSize,
                  ),
                  const SizedBox(width: _labelGap),
                  Flexible(
                    child: Text(
                      isEditing ? l10n.tagLabel : l10n.statsCustomizeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      AnimatedSwitcher(
        duration: _duration,
        reverseDuration: _closeDuration,
        switchInCurve: _curve,
        switchOutCurve: Curves.easeInOutBack,
        transitionBuilder: (child, animation) => AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final factor = math.max(animation.value, 0.0);
            return Align(
              widthFactor: factor,
              child: Transform.scale(scale: factor, child: child),
            );
          },
        ),
        child: isEditing ? _doneButton() : const SizedBox.shrink(),
      ),
    ]);
  }
}

class _TopRow extends StatelessWidget {
  final int streak;
  final WritingSummary summary;
  final VoidCallback onTap;

  const _TopRow({
    required this.streak,
    required this.summary,
    required this.onTap,
  });

  static const double _wideHeight = 200;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final streakTile = StreakTile(streak: streak, onTap: onTap);
    final writingTile = WritingTile(summary: summary, onTap: onTap);
    final minimumHeight = WritingTile.minimumHeightOf(context);

    if (WindowSizeClass.of(context).isWide) {
      return SizedBox(
        height: math.max(_wideHeight, minimumHeight),
        child: Row(children: [
          AspectRatio(aspectRatio: 1, child: streakTile),
          const SizedBox(width: _gap),
          Expanded(child: writingTile),
        ]),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: math.max(minimumHeight, (constraints.maxWidth - _gap) / 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: streakTile),
          const SizedBox(width: _gap),
          Expanded(child: writingTile),
        ]),
      ),
    );
  }
}
