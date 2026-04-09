import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/synchronization/patching/patch.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/template.dart';

import 'conflict.dart';

// TODO: correct database handling, there may be a problem with id clashing. That needs to be handled!

/// Conflict resolver is an interface used to patch conflicts in the database
abstract class ConflictResolver<T> {
  @protected
  final Conflict<T> conflict;
  @protected
  final Database database;

  ConflictResolver(this.conflict, this.database);

  /// Fully accepts the local record, by default this does nothing
  /// as it is not really needed to do anything in that case :)
  Future<void> acceptLocal(T local) async {}

  /// Fully accepts the [remote] record.
  /// Implementation note: this should
  /// either update the local to match remote
  /// or add the remote record.
  Future<void> acceptRemote(T remote);

  /// Deletes the record from the database
  Future<void> deleteRecord(T local);

  /// Partially accepts some changes from remote environment.
  /// [remoteFields] is a list of field names that will be merged
  /// from the [remote] into the database.
  Future<void> acceptPartial(List<String> remoteFields, T local, T remote);
}

class EntryConflictResolver extends ConflictResolver<Entry> {
  EntryConflictResolver(super.conflict, super.database);

  @override
  Future<void> acceptPartial(List<String> remoteFields, Entry local, Entry remote) {
    // TODO: implement acceptPartial
    throw UnimplementedError();
  }

  @override
  Future<void> acceptRemote(Entry remote) {
    return EntryDao.updateOnDB(remote, database);
  }

  @override
  Future<void> deleteRecord(Entry local) {
    // TODO: implement deleteRecord
    throw UnimplementedError();
  }
}