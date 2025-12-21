import 'dart:io';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/image_view_page.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class EntryDetailPage extends StatefulWidget {
  final int index;
  final bool filtered;

  const EntryDetailPage(
      {super.key, required this.index, required this.filtered});

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  late PageController _pageController;
  late ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: widget.index);
    _currentPageNotifier = ValueNotifier<int>(widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);

    var entries = widget.filtered
        ? entriesProvider.filteredEntries
        : entriesProvider.entries;

    // When entries are deleted the current index may be too large
    if (_currentPageNotifier.value >= entries.length) {
      _currentPageNotifier.value = entries.length - 1;
    }

    return Scaffold(
        appBar: AppBar(
          actions: [
            shareButton(context, entries),
            editButton(context, entries)
          ],
        ),
        body: PageView.builder(
            hitTestBehavior: HitTestBehavior.translucent,
            controller: _pageController,
            reverse: true,
            itemCount: entries.length,
            onPageChanged: (int newIndex) {
              _currentPageNotifier.value = newIndex;
            },
            itemBuilder: (context, index) {
              return EntryDetails(entries: entries, index: index);
            }));
  }

  Widget editButton(BuildContext context, List<Entry> entries) {
    return ValueListenableBuilder(
        valueListenable: _currentPageNotifier,
        builder: (context, currentIndex, child) {
          final entriesProvider = Provider.of<EntriesProvider>(context);
          final entryImagesProvider = Provider.of<EntryImagesProvider>(context);

          var entry = entries[currentIndex];
          var images = entryImagesProvider.getForEntry(entry);

          return IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                final editedEntryId = entry.id;
                await Navigator.of(context).push(MaterialPageRoute(
                  allowSnapshotting: false,
                  builder: (context) =>
                      AddEditEntryPage(entry: entry, images: images),
                ));

                // Get the new list of entries since the date of the edited entry
                // may have changed.
                var updatedEntries = widget.filtered
                    ? entriesProvider.filteredEntries
                    : entriesProvider.entries;

                // Find new index of the same entry by ID
                final newIndex =
                    updatedEntries.indexWhere((e) => e.id == editedEntryId);

                // Jump to the new index if found
                if (newIndex != -1 && mounted) {
                  _pageController.jumpToPage(newIndex);
                  _currentPageNotifier.value = newIndex;
                }
              });
        });
  }

  Widget shareButton(BuildContext context, List<Entry> entries) {
    return ValueListenableBuilder(
        valueListenable: _currentPageNotifier,
        builder: (context, currentIndex, child) {
          final entryImagesProvider = Provider.of<EntryImagesProvider>(context);

          var entry = entries[currentIndex];
          var images = entryImagesProvider.getForEntry(entry);

          if (Platform.isAndroid &&
              (images.isNotEmpty || entry.text.isNotEmpty)) {
            return IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () async {
                  String sharedText = "";
                  if (entry.mood != null) {
                    sharedText = "${MoodIcon.getMoodIcon(entry.mood)} ";
                  }
                  sharedText =
                      "$sharedText${DateFormat.yMMMEd(TimeManager.currentLocale(context)).format(entry.timeCreate)}\n${entry.text}";

                  if (images.isNotEmpty) {
                    // Share Image
                    var bytes = await ImageStorage.instance
                        .getBytes(images.first.imgPath);
                    if (bytes != null) {
                      await Share.shareXFiles(
                          [XFile.fromData(bytes, mimeType: "images/*")],
                          fileNameOverrides: [images.first.imgPath],
                          text: sharedText);
                    }
                  } else {
                    // Share text
                    Share.share(sharedText);
                  }
                });
          }

          return Container();
        });
  }
}

class EntryDetails extends StatelessWidget {
  const EntryDetails({
    super.key,
    required this.index,
    required this.entries,
  });

  final int index;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);

    var entry = entries[index];
    var images = entryImagesProvider.getForEntry(entry);

    return Center(
      child: Container(
        constraints: BoxConstraints.loose(const Size.fromWidth(800)),
        child: ListView(
          padding: const EdgeInsets.only(left: 8, right: 8),
          children: [
            if (images.isNotEmpty && images.length > 1)
              SizedBox(
                height: 220,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        child: Center(
                          child: SizedBox(
                            height: 220,
                            width: 220,
                            child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: LocalImageLoader(
                                    imagePath: images[index].imgPath)),
                          ),
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            allowSnapshotting: false,
                            fullscreenDialog: true,
                            builder: (context) => ImageViewPage(
                              images: images,
                              index: index,
                            ),
                          ));
                        },
                      );
                    }),
              ),
            if (images.isNotEmpty && images.length == 1)
              GestureDetector(
                child: Center(
                  child: SizedBox(
                    height: 220,
                    width: 220,
                    child: Card(
                        clipBehavior: Clip.antiAlias,
                        child:
                            LocalImageLoader(imagePath: images.first.imgPath)),
                  ),
                ),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    allowSnapshotting: false,
                    fullscreenDialog: true,
                    builder: (context) => ImageViewPage(
                      images: images,
                      index: 0,
                    ),
                  ));
                },
              ),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMEd(TimeManager.currentLocale(context))
                          .format(entry.timeCreate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    MoodIcon(
                      moodValue: entry.mood,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (entry.text.isNotEmpty)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.only(
                          left: 8, top: 4, bottom: 4, right: 8),
                      child: MarkdownBlock(
                        config: theme.brightness == Brightness.light
                            ? MarkdownConfig.defaultConfig
                            : MarkdownConfig.darkConfig,
                        data: entry.text,
                      ))),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 8),
              child: Text(
                "${AppLocalizations.of(context)!.lastModified}: ${DateFormat.yMMMEd(TimeManager.currentLocale(context)).format(entry.timeModified)} ${DateFormat.jm(TimeManager.currentLocale(context)).format(entry.timeModified)}",
                style: TextStyle(fontSize: 12, color: theme.disabledColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
