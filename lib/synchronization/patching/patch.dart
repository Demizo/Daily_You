import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/synchronization/patching/resolve.dart';
import 'package:sqflite/sqflite.dart';

import 'conflict.dart';

enum Environment {
  local,
  remote
}

class ConflictPatch<T extends Conflict> {
  final T conflict;
  final ConflictResolver resolver;
  bool _isApplied = false;

  ConflictPatch(this.conflict, this.resolver);

  /// Fully accepts the local record
  Future<void> acceptLocal() async {
    if (_isApplied) {
      throw StateError("Conflict is already patched");
    }
    await resolver.acceptLocal(conflict.local);
    _isApplied = true;
  }

  /// Fully accepts the [remote] record.
  Future<void> acceptRemote() async {
    if (_isApplied) {
      throw StateError("Conflict is already patched");
    }
    await resolver.acceptRemote(conflict.remote);
    _isApplied = true;
  }

  // overkill?
  /// Partially accepts some changes from remote environment.
  /// [remoteFields] is a list of field names that will be merged
  /// from the [remote] into the database.
  Future<void> acceptPartial(List<String> remoteFields) async {
    if (_isApplied) {
      throw StateError("Conflict is already patched");
    }
    await resolver.acceptPartial(remoteFields, conflict.local, conflict.remote);
    _isApplied = true;
  }

  Future<void> deleteRecord() async {
    if (_isApplied) {
      throw StateError("Conflict is already patched");
    }
    await resolver.deleteRecord(conflict.local);
    _isApplied = true;
  }

  bool get isApplied => _isApplied;
}