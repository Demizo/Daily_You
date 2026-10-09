// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_song_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/song.dart';
import 'package:flutter/foundation.dart';

class EntrySongsProvider with ChangeNotifier {
  static final EntrySongsProvider instance = EntrySongsProvider._init();

  EntrySongsProvider._init();

  List<EntrySong> songs = [];
  Map<int, List<EntrySong>> _songsByEntryId = {};
  Map<int, EntrySong?> _firstSongByEntryId = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  @visibleForTesting
  set isLoaded(bool value) => _isLoaded = value;

  void _rebuildCache() {
    final map = <int, List<EntrySong>>{};
    final firstMap = <int, EntrySong?>{};
    for (final song in songs) {
      final eId = song.entryId;
      if (eId == null) continue;
      map.putIfAbsent(eId, () => []).add(song);
      firstMap.putIfAbsent(eId, () => song);
    }
    _songsByEntryId = map;
    _firstSongByEntryId = firstMap;
  }

  Future<void> load() async {
    songs = await EntrySongDao.getAll();
    _rebuildCache();
    _isLoaded = true;
    notifyListeners();
  }

  List<EntrySong> getForEntry(Entry entry) {
    if (entry.id == null) return const [];
    return getForEntryId(entry.id!);
  }

  List<EntrySong> getForEntryId(int entryId) {
    return _songsByEntryId[entryId] ?? const [];
  }

  EntrySong? getFirstSongForEntry(int entryId) {
    return _firstSongByEntryId[entryId];
  }

  bool hasSong(int entryId) {
    return (_songsByEntryId[entryId]?.isNotEmpty) ?? false;
  }

  Future<EntrySong> add(EntrySong song, {bool skipUpdate = false}) async {
    final withId = await EntrySongDao.add(song);
    songs.add(withId);
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    if (!skipUpdate) {
      notifyListeners();
    }
    return withId;
  }

  Future<void> remove(EntrySong song) async {
    if (song.id == null) return;
    await EntrySongDao.remove(song.id!);
    songs.removeWhere((s) => s.id == song.id);
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> removeAllForEntry(int entryId) async {
    await EntrySongDao.removeAllForEntry(entryId);
    songs.removeWhere((s) => s.entryId == entryId);
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }
}
