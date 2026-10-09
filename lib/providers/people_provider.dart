// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/people_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/person.dart';
import 'package:flutter/material.dart';

class PeopleProvider with ChangeNotifier {
  static final PeopleProvider instance = PeopleProvider._init();

  PeopleProvider._init();

  List<Person> _people = [];
  List<Person> get people => _people;

  Map<int, List<int>> _entryPeople = {}; // entryId -> list of personIds
  Map<int, List<int>> get entryPeople => _entryPeople;

  Future<void> load() async {
    _people = await PeopleDao.getAll();
    final allEntryPeople = await PeopleDao.getAllEntryPeople();
    final grouped = <int, List<int>>{};
    for (final ep in allEntryPeople) {
      (grouped[ep.entryId] ??= []).add(ep.personId);
    }
    _entryPeople = grouped;
    notifyListeners();
  }

  List<int> getPersonIdsForEntry(int entryId) {
    return _entryPeople[entryId] ?? const [];
  }

  List<Person> getPeopleForEntry(int entryId) {
    final ids = getPersonIdsForEntry(entryId).toSet();
    return _people.where((p) => ids.contains(p.id)).toList();
  }

  List<Entry> getEntriesForPerson(int personId, List<Entry> allEntries) {
    final targetPerson = _people.where((p) => p.id == personId).firstOrNull;
    if (targetPerson == null) return const [];

    final nameLower = targetPerson.name.toLowerCase();
    final tagPattern = '@$nameLower';

    final matches = allEntries.where((entry) {
      final entryId = entry.id;
      final assigned = entryId != null ? _entryPeople[entryId] : null;
      if (assigned != null && assigned.contains(personId)) {
        return true;
      }
      if (entry.text.toLowerCase().contains(tagPattern)) {
        return true;
      }
      return false;
    }).toList();

    matches.sort((a, b) => b.timeCreate.compareTo(a.timeCreate));
    return matches;
  }

  int getEntryCountForPerson(int personId, List<Entry> allEntries) {
    return getEntriesForPerson(personId, allEntries).length;
  }

  Future<Person> addPerson(String name, {String? note, int? color}) async {
    final clean = name.trim().replaceFirst(RegExp(r'^@+'), '');
    final existing = _people
        .where((p) => p.name.toLowerCase() == clean.toLowerCase())
        .firstOrNull;
    if (existing != null) return existing;

    final now = DateTime.now();
    final newPerson = Person(
      name: clean,
      note: note,
      color: color,
      timeCreate: now,
      timeModified: now,
    );
    final saved = await PeopleDao.add(newPerson);
    _people = await PeopleDao.getAll();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
    return saved;
  }

  Future<void> updatePerson(Person person) async {
    await PeopleDao.update(person);
    _people = await PeopleDao.getAll();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> removePerson(Person person) async {
    await PeopleDao.remove(person.id!);
    _people = await PeopleDao.getAll();
    final allEntryPeople = await PeopleDao.getAllEntryPeople();
    final grouped = <int, List<int>>{};
    for (final ep in allEntryPeople) {
      (grouped[ep.entryId] ??= []).add(ep.personId);
    }
    _entryPeople = grouped;
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> setEntryPeople(int entryId, List<int> personIds) async {
    await PeopleDao.setPeopleForEntry(entryId, personIds);
    _entryPeople[entryId] = personIds.toSet().toList();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  void removeForEntry(int entryId) {
    _entryPeople.remove(entryId);
    notifyListeners();
  }

  List<Person> search(String query) {
    final clean = query.trim().toLowerCase().replaceFirst(RegExp(r'^@+'), '');
    if (clean.isEmpty) return _people;
    return _people
        .where((p) =>
            p.name.toLowerCase().contains(clean) ||
            (p.note != null && p.note!.toLowerCase().contains(clean)))
        .toList();
  }
}
