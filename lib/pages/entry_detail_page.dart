import 'dart:io';

import 'package:daily_you/stats_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/image_view_page.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class EntryDetailPage extends StatefulWidget {
  final int index;

  const EntryDetailPage({
    super.key,
    required this.index,
  });

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
    final statsProvider = Provider.of<StatsProvider>(context);
    return Scaffold(
        appBar: AppBar(
          actions: [shareButton(context), editButton(context)],
        ),
        body: PageView.builder(
            hitTestBehavior: HitTestBehavior.translucent,
            controller: _pageController,
            reverse: true,
            itemCount: statsProvider.entries.length,
            onPageChanged: (int newIndex) {
              _currentPageNotifier.value = newIndex;
            },
            itemBuilder: (context, index) {
              return EntryDetails(index: index);
            }));
  }

  Widget editButton(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _currentPageNotifier,
        builder: (context, currentIndex, child) {
          final statsProvider = Provider.of<StatsProvider>(context);

          var entry = statsProvider.entries[currentIndex];
          var images = statsProvider.images
              .where((img) => img.entryId == entry.id!)
              .toList();

          return IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) =>
                      AddEditEntryPage(entry: entry, images: images),
                ));
              });
        });
  }

  Widget shareButton(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _currentPageNotifier,
        builder: (context, currentIndex, child) {
          final statsProvider = Provider.of<StatsProvider>(context);

          var entry = statsProvider.entries[currentIndex];
          var images = statsProvider.images
              .where((img) => img.entryId == entry.id!)
              .toList();

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
                      "$sharedText${DateFormat.yMMMEd(WidgetsBinding.instance.platformDispatcher.locale.toString()).format(entry.timeCreate)}\n${entry.text}";

                  if (images.isNotEmpty) {
                    // Share Image
                    var bytes = await EntriesDatabase.instance
                        .getImgBytes(images.first.imgPath);
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
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsProvider = Provider.of<StatsProvider>(context);

    var entry = statsProvider.entries[index];
    var images =
        statsProvider.images.where((img) => img.entryId == entry.id!).toList();

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
                          if (await EntriesDatabase.instance
                                  .getImgBytes(images[index].imgPath) !=
                              null) {
                            await Navigator.of(context).push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => ImageViewPage(
                                images: images,
                                index: index,
                              ),
                            ));
                          }
                        },
                      );
                    }),
              ),
            if (images.isNotEmpty && images.length == 1)
              GestureDetector(
                child: Center(
                  child: Container(
                    alignment: Alignment.center,
                    height: 220,
                    width: 220,
                    child: Card(
                        clipBehavior: Clip.antiAlias,
                        child:
                            LocalImageLoader(imagePath: images.first.imgPath)),
                  ),
                ),
                onTap: () async {
                  if (await EntriesDatabase.instance
                          .getImgBytes(images.first.imgPath) !=
                      null) {
                    await Navigator.of(context).push(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => ImageViewPage(
                        images: images,
                        index: 0,
                      ),
                    ));
                  }
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
                      DateFormat.yMMMEd(WidgetsBinding
                              .instance.platformDispatcher.locale
                              .toString())
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
                "${AppLocalizations.of(context)!.lastModified}: ${DateFormat.yMMMEd(WidgetsBinding.instance.platformDispatcher.locale.toString()).format(entry.timeModified)} ${DateFormat.jm(WidgetsBinding.instance.platformDispatcher.locale.toString()).format(entry.timeModified)}",
                style: TextStyle(fontSize: 12, color: theme.disabledColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
