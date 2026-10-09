// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/utils/webdav_sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();
  setUpAll(sqfliteFfiInit);

  group('WebDavSyncEngine (F21)', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      AppDatabase.instance.database = db;
      try {
        await AppDatabase.instance.createSchema(db);
      } catch (_) {}

      NetworkGate.debugOverrideCompiledIn = true;
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, true);
      await ConfigProvider.instance
          .set(Settings.webDavUrl, 'https://example.com/webdav');
      await ConfigProvider.instance.set(Settings.webDavUsername, 'user');
      await ConfigProvider.instance.set(Settings.webDavPassword, 'pass');
      await ConfigProvider.instance.set(Settings.syncTombstones, '[]');
    });

    tearDown(() async {
      WebDavSyncEngine.instance.httpOverride = null;
      NetworkGate.debugOverrideCompiledIn = null;
      await db.close();
      AppDatabase.instance.database = null;
    });

    test('records and retrieves tombstones', () async {
      expect(WebDavSyncEngine.getTombstones(), isEmpty);

      await WebDavSyncEngine.recordTombstone(42);
      final tombstones = WebDavSyncEngine.getTombstones();
      expect(tombstones.length, 1);
      expect(tombstones.first.id, 42);
    });

    test('fails quietly when network is disabled', () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, false);

      final result = await WebDavSyncEngine.instance.sync();
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('disabled'));
    });

    test('uploads local entries and processes tombstones', () async {
      final now = DateTime.now();
      await EntryDao.add(Entry(
        id: 1,
        text: 'Local test entry',
        mood: 1,
        timeCreate: now,
        timeModified: now,
      ));

      await WebDavSyncEngine.recordTombstone(2);

      final sentRequests = <String>[];

      WebDavSyncEngine.instance.httpOverride =
          (method, uri, headers, body) async {
        sentRequests.add('$method ${uri.path}');
        if (method == 'PROPFIND') {
          return (
            statusCode: 207,
            body: Uint8List.fromList(
                utf8.encode('<xml><file>entry_2.json</file></xml>')),
          );
        }
        return (
          statusCode: 200,
          body: Uint8List.fromList(utf8.encode('OK')),
        );
      };

      final result = await WebDavSyncEngine.instance.sync();
      expect(result.success, isTrue);
      expect(result.uploaded, 1);
      expect(result.deleted, 1);

      // Verify DELETE was issued for tombstoned entry 2
      expect(sentRequests.any((r) => r.contains('DELETE') && r.contains('entry_2.json')), isTrue);
      // Verify PUT was issued for local entry 1
      expect(sentRequests.any((r) => r.contains('PUT') && r.contains('entry_1.json')), isTrue);
    });
  });
}
