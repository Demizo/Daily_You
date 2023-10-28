import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/image_view_page.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';

class EntryDetailPage extends StatefulWidget {
  final int entryId;

  const EntryDetailPage({
    Key? key,
    required this.entryId,
  }) : super(key: key);

  @override
  _EntryDetailPageState createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  late Entry entry;
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
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: isLoading ? [] : [shareButton(), editButton()],
      ),
      body: isLoading
          ? const Center(child: SizedBox())
          : Center(
              child: Container(
                constraints: BoxConstraints.loose(const Size.fromWidth(800)),
                child: ListView(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  children: [
                    if (entry.imgPath != null)
                      GestureDetector(
                        child: Center(
                          child: Container(
                            alignment: Alignment.center,
                            height: 300,
                            width: 300,
                            child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: LocalImageLoader(
                                    imagePath: entry.imgPath!)),
                          ),
                        ),
                        onTap: () async {
                          final imgDir = await EntriesDatabase.instance
                              .getImgDatabasePath();
                          if (await File("$imgDir/${entry.imgPath!}")
                              .exists()) {
                            await Navigator.of(context).push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                                  ImageViewPage(imgName: entry.imgPath!),
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
                              DateFormat.yMMMEd().format(entry.timeCreate),
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
                              child: md.MarkdownBody(
                                data: entry.text,
                                styleSheet: md.MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontSize: 16,
                                    ),
                                    checkbox: TextStyle(
                                        color: theme.colorScheme.primary)),
                              ),
                            ),
                          )
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
          builder: (context) => AddEditEntryPage(entry: entry),
        ));

        refreshEntry();
      });

  Widget shareButton() {
    if (Platform.isAndroid && entry.imgPath != null) {
      return IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () async {
            final tempDir = await getTemporaryDirectory();
            final imgDir = await EntriesDatabase.instance.getImgDatabasePath();

            if (await File("$imgDir/${entry.imgPath!}").exists()) {
              File temp = await File("$imgDir/${entry.imgPath!}")
                  .copy("${tempDir.path}/${entry.imgPath!}");

              ShareExtend.share(temp.path, "image",
                  extraText: DateFormat.yMMMEd().format(entry.timeCreate));
            }
          });
    }

    return Container();
  }
}
