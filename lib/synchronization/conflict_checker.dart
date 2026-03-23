import 'package:daily_you/models/entry.dart';
import 'package:flutter/cupertino.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

class EntryConflict {
  final Entry localEntry;
  final Entry remoteEntry;

  final List<String> conflictingFields;

  EntryConflict(this.localEntry, this.remoteEntry, this.conflictingFields);

  bool get isTextConflict => conflictingFields.contains(EntryFields.text);

  bool get isMoodConflict => conflictingFields.contains(EntryFields.mood);

  bool get isTimeCreateConflict =>
      conflictingFields.contains(EntryFields.timeCreate);

  bool get isTimeModifiedConflict =>
      conflictingFields.contains(EntryFields.timeModified);

  bool get isRemoteAhead =>
      localEntry.timeModified.isBefore(remoteEntry.timeModified);

  Text createTextDiff() {
    // there is potential here to create a patching system here
    DiffMatchPatch dmp = DiffMatchPatch();

    List<Diff> diffs = dmp.diff(localEntry.text, remoteEntry.text);
    dmp.diffCleanupSemantic(diffs);

    List<TextSpan> textSpans = [];

    for (var diff in diffs) {
      if (diff.operation == DIFF_INSERT) {
        textSpans.add(
            TextSpan(
              text: diff.text,
              style: const TextStyle(color: CupertinoColors.activeGreen),
            )
        );
      } else if (diff.operation == DIFF_DELETE) {
        textSpans.add(
            TextSpan(
              text: diff.text,
              style: const TextStyle(color: CupertinoColors.systemRed),
            )
        );
      } else if (diff.operation == DIFF_EQUAL) {
        textSpans.add(TextSpan(text: diff.text));
      }
    }

    return Text.rich(TextSpan(children: textSpans));
  }
}

class ConflictChecker {
  // Fast lookup for entries by ID
  Map<int, Entry> localEntries = {};
  Map<int, Entry> remoteEntries = {};

  void putLocal(Entry entry) {
    localEntries[entry.id!] = entry;
  }

  void putRemote(Entry entry) {
    remoteEntries[entry.id!] = entry;
  }

  List<EntryConflict> findConflicts() {
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
}
