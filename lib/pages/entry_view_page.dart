import 'dart:io';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/image_view_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class EntryViewPage extends StatefulWidget {
  const EntryViewPage({
    super.key,
    required this.entryId,
    required this.onEntryEdited,
  });

  final int entryId;
  final Function(int entryId) onEntryEdited;

  @override
  State<EntryViewPage> createState() => _EntryViewPageState();
}

class _EntryViewPageState extends State<EntryViewPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);

    final entry = entriesProvider.entries
        .where((e) => e.id == widget.entryId)
        .firstOrNull;
    if (entry == null) return const Scaffold();

    final images = entryImagesProvider.getForEntry(entry);

    return Scaffold(
      appBar: AppBar(
        actions: [
          _shareButton(context, entry, images),
          _editButton(context, entry, images),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints.loose(const Size.fromWidth(800)),
          child: ListView(
            padding: const EdgeInsets.only(left: 8, right: 8),
            children: [
              if (images.isNotEmpty && images.length > 1)
                _imagesList(context, images),
              if (images.isNotEmpty && images.length == 1)
                GestureDetector(
                  child: Center(
                    child: SizedBox(
                      height: 220,
                      width: 220,
                      child: Card.filled(
                          clipBehavior: Clip.antiAlias,
                          child: LocalImageLoader(
                              imagePath: images.first.imgPath)),
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
              Card.filled(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8, top: 4, bottom: 4, right: 8),
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
                Card.filled(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 8, top: 4, bottom: 4, right: 8),
                        child: ScaledMarkdown(
                          data: entry.text,
                        ))),
              Padding(
                padding: const EdgeInsets.only(
                    left: 8, top: 4, bottom: 18, right: 8),
                child: Text(
                  "${AppLocalizations.of(context)!.lastModified}: ${DateFormat.yMMMEd(TimeManager.currentLocale(context)).format(entry.timeModified)} ${DateFormat.jm(TimeManager.currentLocale(context)).format(entry.timeModified)}",
                  style: TextStyle(fontSize: 12, color: theme.disabledColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editButton(BuildContext context, entry, List<EntryImage> images) {
    return IconButton(
        icon: const Icon(Icons.edit_rounded),
        onPressed: () async {
          await Navigator.of(context).push(PageRouteBuilder(
            allowSnapshotting: false,
            fullscreenDialog: true,
            pageBuilder: (context, _, __) =>
                AddEditEntryPage(entry: entry, images: images),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ));

          widget.onEntryEdited(entry.id);
        });
  }

  Widget _shareButton(BuildContext context, entry, List<EntryImage> images) {
    if (Platform.isAndroid && (images.isNotEmpty || entry.text.isNotEmpty)) {
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
              var bytes =
                  await ImageStorage.instance.getBytes(images.first.imgPath);
              if (bytes != null) {
                await Share.shareXFiles(
                    [XFile.fromData(bytes, mimeType: "images/*")],
                    fileNameOverrides: [images.first.imgPath],
                    text: sharedText);
              }
            } else {
              Share.share(sharedText);
            }
          });
    }
    return Container();
  }

  Widget _imagesList(BuildContext context, List<EntryImage> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const imageSize = 160.0;
        final fits = images.length * imageSize <= constraints.maxWidth;

        if (fits) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: images
                  .map(
                    (image) => SizedBox(
                      width: imageSize,
                      child: GestureDetector(
                        child: Center(
                          child: SizedBox(
                            height: imageSize,
                            width: imageSize,
                            child: Card.filled(
                                clipBehavior: Clip.antiAlias,
                                child:
                                    LocalImageLoader(imagePath: image.imgPath)),
                          ),
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            allowSnapshotting: false,
                            fullscreenDialog: true,
                            builder: (context) => ImageViewPage(
                              images: images,
                              index: images.indexWhere((x) => x.id == image.id),
                            ),
                          ));
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return SizedBox(
          height: imageSize,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  child: Center(
                    child: SizedBox(
                      height: imageSize,
                      width: imageSize,
                      child: Card.filled(
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
        );
      },
    );
  }
}
