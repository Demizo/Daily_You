import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryTimelinePage extends StatefulWidget {
  const EntryTimelinePage({
    super.key,
    required this.header,
    required this.getEntries,
    required this.labelBuilder,
  });

  final String header;
  final List<Entry> Function() getEntries;
  final String Function(Entry) labelBuilder;

  @override
  State<EntryTimelinePage> createState() => _EntryTimelinePageState();
}

class _EntryTimelinePageState extends State<EntryTimelinePage> {
  @override
  Widget build(BuildContext context) {
    Provider.of<EntriesProvider>(context);
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);

    final entries = widget.getEntries();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entries.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.header)),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final entryImages = entryImagesProvider.getForEntry(entry);
          final label = widget.labelBuilder(entry);
          return AspectRatio(
            aspectRatio: 2.2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        color: index == 0
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 3,
                          color: index == entries.length - 1
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        final id = entry.id;
                        if (id == null) return;
                        Navigator.of(context).push(MaterialPageRoute(
                          allowSnapshotting: false,
                          builder: (context) => EntriesListPage(
                            index: EntriesProvider.instance.getIndexOfEntry(id),
                            getEntries: () => EntriesProvider.instance.entries,
                          ),
                        ));
                      },
                      child: LargeEntryCardWidget(
                        title: label,
                        entry: entry,
                        images: entryImages,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
