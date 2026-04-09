import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/synchronization/patching/patch.dart';
import 'package:daily_you/synchronization/patching/resolve.dart';
import 'package:flutter/cupertino.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:sqflite/sqflite.dart';

// TODO: handle deletion or creation (empty local/remote)
abstract class Conflict<T> {
  final T local;
  final T remote;

  final List<String> conflictingFields;
  Conflict(this.local, this.remote, this.conflictingFields);

  // used to order conflicts, the most recent change should be resolved first
  DateTime get localTimeCreate;

  ConflictResolver<T> _createResolver(Database database);

  ConflictPatch patch(Database database) {
    return ConflictPatch(this, _createResolver(database));
  }
}

class EntryConflict extends Conflict<Entry> {
  EntryConflict(super.local, super.remote, super.conflictingFields);

  bool get isTextConflict => conflictingFields.contains(EntryFields.text);

  bool get isMoodConflict => conflictingFields.contains(EntryFields.mood);

  bool get isTimeCreateConflict =>
      conflictingFields.contains(EntryFields.timeCreate);

  bool get isTimeModifiedConflict =>
      conflictingFields.contains(EntryFields.timeModified);

  bool get isRemoteAhead =>
      local.timeModified.isBefore(remote.timeModified);

  Text createTextDiff() {
    // there is potential here to create a patching system here
    DiffMatchPatch dmp = DiffMatchPatch();

    List<Diff> diffs = dmp.diff(local.text, remote.text);
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

  @override
  DateTime get localTimeCreate => local.timeCreate;

  @override
  ConflictResolver<Entry> _createResolver(Database database) {
    // TODO: implement _createResolver
    throw UnimplementedError();
  }
}

class EntryImageConflict extends Conflict<EntryImage> {
  EntryImageConflict(super.local, super.remote, super.conflictingFields);

  bool get isImgPathConflict => conflictingFields.contains(EntryImageFields.imgPath);
  bool get isEntryIdConflict => conflictingFields.contains(EntryImageFields.entryId);
  bool get isImgRankConflict => conflictingFields.contains(EntryImageFields.imgRank);
  bool get isTimeCreateConflict => conflictingFields.contains(EntryImageFields.timeCreate);

  bool get isRemoteAhead => local.timeCreate.isBefore(remote.timeCreate);

  @override
  DateTime get localTimeCreate => local.timeCreate;

  @override
  ConflictResolver<EntryImage> _createResolver(Database database) {
    // TODO: implement _createResolver
    throw UnimplementedError();
  }
}

class TemplateConflict extends Conflict<Template> {
  TemplateConflict(super.local, super.remote, super.conflictingFields);

  bool get isNameConflict => conflictingFields.contains(TemplatesFields.name);
  bool get isTextConflict => conflictingFields.contains(TemplatesFields.text);
  bool get isTimeCreateConflict => conflictingFields.contains(TemplatesFields.timeCreate);

  bool get isRemoteAhead => local.timeModified.isBefore(remote.timeModified);

  @override
  DateTime get localTimeCreate => local.timeCreate;

  @override
  ConflictResolver<Template> _createResolver(Database database) {
    // TODO: implement _createResolver
    throw UnimplementedError();
  }
}