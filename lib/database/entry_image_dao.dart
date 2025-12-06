import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/image.dart';

class EntryImageDao {
  static Future<List<EntryImage>> getAll() async {
    final result = await EntriesDatabase.instance.database!
        .query(imagesTable, orderBy: '${EntryImageFields.imgRank} DESC');

    return result.map((json) => EntryImage.fromJson(json)).toList();
  }

  static Future<List<EntryImage>> getForEntry(int entryId) async {
    List<EntryImage> entryImages = List.empty(growable: true);

    final maps = await EntriesDatabase.instance.database!.query(imagesTable,
        where: '${EntryImageFields.entryId} = ?',
        whereArgs: [entryId],
        orderBy: '${EntryImageFields.imgRank} DESC');

    for (final map in maps) {
      entryImages.add(EntryImage.fromJson(map));
    }

    return entryImages;
  }

  static Future<EntryImage> add(EntryImage entryImage) async {
    final id = await EntriesDatabase.instance.database!
        .insert(imagesTable, entryImage.toJson());

    return entryImage.copy(id: id);
  }

  static Future<int> remove(EntryImage entryImage) async {
    final removedId = await EntriesDatabase.instance.database!.delete(
      imagesTable,
      where: '${EntryImageFields.id} = ?',
      whereArgs: [entryImage.id],
    );
    return removedId;
  }

  static Future<int> update(EntryImage image) async {
    final id = await EntriesDatabase.instance.database!.update(
      imagesTable,
      image.toJson(),
      where: '${EntryImageFields.id} = ?',
      whereArgs: [image.id],
    );
    return id;
  }
}
