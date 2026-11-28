// Logdaloop: Feed tab, an Instagram-style vertical scroll through entries.

import 'dart:math' as math;

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/widgets/content_width_limit.dart';
import 'package:daily_you/widgets/feed_card.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Logdaloop-only strings, kept out of the upstream .arb files on purpose.
const String feedPageTitle = 'Feed';
const String feedEmptyLabel = 'No entries yet';

/// Shows every entry newest first as a [FeedCard].
///
/// Entries come from [EntriesProvider], which the app already keeps in
/// memory. Cards are built lazily by [ListView.builder], and the list grows
/// in batches of [batchSize] as the user nears the end, so only a small
/// window of cards (and their photos) is ever built and decoded.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  static const int batchSize = 20;

  /// Load the next batch when this many cards remain below the last built one.
  static const int loadAheadCards = 5;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with AutomaticKeepAliveClientMixin {
  int _visibleCount = FeedPage.batchSize;
  bool _loadScheduled = false;

  @override
  bool get wantKeepAlive => true;

  void _scheduleLoadMore(int total) {
    if (_loadScheduled || _visibleCount >= total) return;
    _loadScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (!mounted) return;
      setState(() {
        _visibleCount = math.min(_visibleCount + FeedPage.batchSize, total);
      });
    });
  }

  void _openEntry(Entry entry) {
    final id = entry.id;
    if (id == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntriesListPage(
        index: EntriesProvider.instance.getIndexOfEntry(id),
        getEntries: () => EntriesProvider.instance.entries,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    // Already sorted newest first by EntryStore.
    final entries = context.watch<EntriesProvider>().entries;
    final attachments = context.watch<EntryAttachmentsProvider>();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dynamic_feed_rounded,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              feedEmptyLabel,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final count = math.min(_visibleCount, entries.length);

    // Uses the PrimaryScrollController from MobileScaffold, so the app bar
    // elevation behaves like the other tabs.
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: count,
      itemBuilder: (context, index) {
        if (index >= count - FeedPage.loadAheadCards) {
          _scheduleLoadMore(entries.length);
        }
        final entry = entries[index];
        final images = entry.id == null
            ? const <EntryAttachment>[]
            : [
                for (final attachment
                    in attachments.getCoverCandidatesForEntry(entry.id!))
                  if (attachment.type == AttachmentType.image) attachment,
              ];
        return ContentWidthLimit(
          child: FeedCard(
            key: ValueKey(entry.id),
            entry: entry,
            images: images,
            onTap: () => _openEntry(entry),
          ),
        );
      },
    );
  }
}
