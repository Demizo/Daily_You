// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_location_dao.dart';
import 'package:daily_you/models/location.dart';
import 'package:flutter/foundation.dart';

class EntryLocationsProvider with ChangeNotifier {
  static final EntryLocationsProvider instance =
      EntryLocationsProvider._init();

  EntryLocationsProvider._init();

  Map<int, EntryLocation> _locationsByEntryId = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final all = await EntryLocationDao.getAll();
    _locationsByEntryId = {for (final l in all) l.entryId!: l};
    _isLoaded = true;
    notifyListeners();
  }

  EntryLocation? getForEntryId(int entryId) => _locationsByEntryId[entryId];

  Future<void> setLocation(EntryLocation location) async {
    final saved = await EntryLocationDao.setForEntry(location);
    _locationsByEntryId[location.entryId!] = saved;
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> removeForEntry(int entryId) async {
    await EntryLocationDao.removeForEntry(entryId);
    _locationsByEntryId.remove(entryId);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }
}
