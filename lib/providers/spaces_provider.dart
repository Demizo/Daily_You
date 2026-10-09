// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/spaces_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/space.dart';
import 'package:flutter/material.dart';

class SpacesProvider with ChangeNotifier {
  static final SpacesProvider instance = SpacesProvider._init();

  SpacesProvider._init();

  List<Space> _spaces = [];
  List<Space> get spaces => _spaces;

  Map<int, int> _entrySpaces = {}; // entryId -> spaceId
  Map<int, int> get entrySpaces => _entrySpaces;

  Future<void> load() async {
    _spaces = await SpacesDao.getAll();
    // Remove auto-generated default "Personal" space if present
    final defaultPersonal = _spaces
        .where((s) => s.isDefault && s.name.toLowerCase() == 'personal')
        .firstOrNull;
    if (defaultPersonal != null && defaultPersonal.id != null) {
      await SpacesDao.remove(defaultPersonal.id!);
      _spaces = await SpacesDao.getAll();
    }
    final allEntrySpaces = await SpacesDao.getAllEntrySpaces();
    _entrySpaces = {for (final es in allEntrySpaces) es.entryId: es.spaceId};
    notifyListeners();
  }

  Space? getSpaceForEntry(int entryId) {
    final spaceId = _entrySpaces[entryId];
    if (spaceId == null) {
      return null;
    }
    return _spaces.where((s) => s.id == spaceId).firstOrNull;
  }

  int? getSpaceIdForEntry(int entryId) {
    return _entrySpaces[entryId];
  }

  List<Entry> getEntriesForSpace(int spaceId, List<Entry> allEntries) {
    final targetSpace = _spaces.where((s) => s.id == spaceId).firstOrNull;
    if (targetSpace == null) return const [];

    final spaceNameLower = targetSpace.name.toLowerCase();

    final matches = allEntries.where((entry) {
      final entryId = entry.id;
      final assignedId = entryId != null ? _entrySpaces[entryId] : null;

      if (assignedId != null) {
        return assignedId == spaceId;
      }

      // Check if entry text specifically tags or mentions this space
      if (entry.text.toLowerCase().contains('#$spaceNameLower') ||
          entry.text.toLowerCase().contains('[$spaceNameLower]')) {
        return true;
      }

      return false;
    }).toList();

    matches.sort((a, b) => b.timeCreate.compareTo(a.timeCreate));
    return matches;
  }

  int getEntryCountForSpace(int spaceId, List<Entry> allEntries) {
    return getEntriesForSpace(spaceId, allEntries).length;
  }

  Future<Space> addSpace(String name) async {
    final clean = name.trim();
    final existing = _spaces.where((s) => s.name.toLowerCase() == clean.toLowerCase()).firstOrNull;
    if (existing != null) return existing;

    final now = DateTime.now();
    final newSpace = Space(
      name: clean,
      isDefault: false,
      timeCreate: now,
      timeModified: now,
    );
    final saved = await SpacesDao.add(newSpace);
    _spaces = await SpacesDao.getAll();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
    return saved;
  }

  Future<void> updateSpace(Space space) async {
    await SpacesDao.update(space);
    _spaces = await SpacesDao.getAll();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> removeSpace(Space space) async {
    if (space.isDefault) return; // Cannot delete default space
    await SpacesDao.remove(space.id!);
    _spaces = await SpacesDao.getAll();
    final allEntrySpaces = await SpacesDao.getAllEntrySpaces();
    _entrySpaces = {for (final es in allEntrySpaces) es.entryId: es.spaceId};
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> assignEntryToSpace(int entryId, int spaceId) async {
    await SpacesDao.setSpaceForEntry(entryId, spaceId);
    _entrySpaces[entryId] = spaceId;
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> unassignEntryFromSpace(int entryId) async {
    await SpacesDao.removeForEntry(entryId);
    _entrySpaces.remove(entryId);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  void removeForEntry(int entryId) {
    _entrySpaces.remove(entryId);
    notifyListeners();
  }
}
