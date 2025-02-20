import 'dart:io';

import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/image_view_page.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:share_plus/share_plus.dart';

class EntryDetailPage extends StatefulWidget {
  final int entryId;

  const EntryDetailPage({
    super.key,
    required this.entryId,
  });

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  late Entry entry;
  late List<EntryImage> images;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    refreshEntry();
  }

  Future refreshEntry() async {
    setState(() => isLoading = true);

    var entryOption = await EntriesDatabase.instance.getEntry(widget.entryId);
    if (entryOption != null) {
      entry = entryOption;
      images = await EntriesDatabase.instance.getImagesForEntry(entry.id!);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: isLoading ? [] : [shareButton(context), editButton()],
      ),
      body: isLoading
          ? const Center(child: SizedBox())
          : Center(
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
                                    await Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (context) => ImageViewPage(
                                          imgName: images[index].imgPath),
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
                                child: LocalImageLoader(
                                    imagePath: images.first.imgPath)),
                          ),
                        ),
                        onTap: () async {
                          if (await EntriesDatabase.instance
                                  .getImgBytes(images.first.imgPath) !=
                              null) {
                            await Navigator.of(context).push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                                  ImageViewPage(imgName: images.first.imgPath),
                            ));
                          }
                        },
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 8, top: 4, bottom: 4, right: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat.yMMMEd(WidgetsBinding.instance.platformDispatcher.locale.toString())
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
                    entry.text.isNotEmpty
                        ? Card(
                            child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8, top: 4, bottom: 4, right: 8),
                                child: MarkdownBlock(
                                  config: theme.brightness == Brightness.light
                                      ? MarkdownConfig.defaultConfig
                                      : MarkdownConfig.darkConfig,
                                  data: entry.text,
                                )))
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, top: 4, bottom: 4, right: 8),
                              child: Text(
                                "No text for this log...\n\n",
                                style: TextStyle(
                                    color: theme.disabledColor, fontSize: 18),
                              ),
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8, top: 4, bottom: 4, right: 8),
                      child: Text(
                        "${AppLocalizations.of(context)!.lastModified}: ${DateFormat.yMMMEd(WidgetsBinding.instance.platformDispatcher.locale.toString()).format(entry.timeModified)} ${DateFormat.jm(WidgetsBinding.instance.platformDispatcher.locale.toString()
).format(entry.timeModified)}",
                        style:
                            TextStyle(fontSize: 12, color: theme.disabledColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget editButton() => IconButton(
      icon: const Icon(Icons.edit_rounded),
      onPressed: () async {
        if (isLoading) return;

        await Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => AddEditEntryPage(entry: entry, images: images),
        ));

        refreshEntry();
      });

  Widget shareButton(BuildContext context) {
    if (Platform.isAndroid && (images.isNotEmpty || entry.text.isNotEmpty)) {
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
  }
}
