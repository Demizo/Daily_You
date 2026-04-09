import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/template.dart';
import 'package:sqflite/sqflite.dart';

import 'conflict.dart';


class ConflictFinder {
  static List<EntryConflict> findEntryConflicts(List<Entry> localEntriesList, List<Entry> remoteEntriesList) {

    // lookup map
    Map<int, Entry> localEntries = localEntriesList.asMap().map((index, entry) => MapEntry(entry.id!, entry));
    Map<int, Entry> remoteEntries = remoteEntriesList.asMap().map((index, entry) => MapEntry(entry.id!, entry));

    List<EntryConflict> conflicts = [];

    for (var id in localEntries.keys) {
      if (remoteEntries.containsKey(id)) {
        var localEntry = localEntries[id]!;
        var remoteEntry = remoteEntries[id]!;

        List<String> conflictingFields = [];

        if (localEntry.text != remoteEntry.text) {
          conflictingFields.add(EntryFields.text);
        }
        if (localEntry.mood != remoteEntry.mood) {
          conflictingFields.add(EntryFields.mood);
        }
        if (localEntry.timeCreate != remoteEntry.timeCreate) {
          conflictingFields.add(EntryFields.timeCreate);
        }
        if (localEntry.timeModified != remoteEntry.timeModified) {
          conflictingFields.add(EntryFields.timeModified);
        }

        if (conflictingFields.isNotEmpty) {
          conflicts
              .add(EntryConflict(localEntry, remoteEntry, conflictingFields));
        }
      }
    }

    return conflicts;
  }

  static List<EntryImageConflict> findEntryImageConflicts(List<EntryImage> localImagesList, List<EntryImage> remoteImagesList) {
    // lookup map
    Map<String, EntryImage> localImages = localImagesList.asMap().map((index, image) => MapEntry(image.imgPath, image));
    Map<String, EntryImage> remoteImages = remoteImagesList.asMap().map((index, image) => MapEntry(image.imgPath, image));

    List<EntryImageConflict> conflicts = [];

    for (var imgPath in localImages.keys) {
      if (remoteImages.containsKey(imgPath)) {
        var localImage = localImages[imgPath]!;
        var remoteImage = remoteImages[imgPath]!;

        List<String> conflictingFields = [];

        if (localImage.imgPath != remoteImage.imgPath) {
          conflictingFields.add(EntryImageFields.imgPath);
        }
        if (localImage.entryId != remoteImage.entryId) {
          conflictingFields.add(EntryImageFields.entryId);
        }
        if (localImage.imgRank != remoteImage.imgRank) {
          conflictingFields.add(EntryImageFields.imgRank);
        }
        if (localImage.timeCreate != remoteImage.timeCreate) {
          conflictingFields.add(EntryImageFields.timeCreate);
        }

        if (conflictingFields.isNotEmpty) {
          conflicts
              .add(EntryImageConflict(localImage, remoteImage, conflictingFields));
        }
      }
    }

    return conflicts;
  }

  static List<TemplateConflict> findTemplateConflicts(List<Template> localTemplatesList, List<Template> remoteTemplatesList) {
    // lookup map
    Map<int, Template> localTemplates = localTemplatesList.asMap().map((index, template) => MapEntry(template.id!, template));
    Map<int, Template> remoteTemplates = remoteTemplatesList.asMap().map((index, template) => MapEntry(template.id!, template));

    List<TemplateConflict> conflicts = [];

    for (var id in localTemplates.keys) {
      if (remoteTemplates.containsKey(id)) {
        var localTemplate = localTemplates[id]!;
        var remoteTemplate = remoteTemplates[id]!;

        List<String> conflictingFields = [];

        if (localTemplate.name != remoteTemplate.name) {
          conflictingFields.add(TemplatesFields.name);
        }
        if (localTemplate.text != remoteTemplate.text) {
          conflictingFields.add(TemplatesFields.text);
        }
        if (localTemplate.timeCreate != remoteTemplate.timeCreate) {
          conflictingFields.add(TemplatesFields.timeCreate);
        }
        if (localTemplate.timeModified != remoteTemplate.timeModified) {
          conflictingFields.add(TemplatesFields.timeModified);
        }

        if (conflictingFields.isNotEmpty) {
          conflicts
              .add(TemplateConflict(localTemplate, remoteTemplate, conflictingFields));
        }
      }
    }

    return conflicts;
  }
}