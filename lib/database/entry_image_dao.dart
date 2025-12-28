import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/image.dart';

class EntryImageDao {
  static Future<List<EntryImage>> getAll() async {
    final result = await AppDatabase.instance.database!
        .query(imagesTable, orderBy: '${EntryImageFields.imgRank} DESC');

    return result.map((json) => EntryImage.fromJson(json)).toList();
  }

  static Future<List<EntryImage>> getForEntry(int entryId) async {
    List<EntryImage> entryImages = List.empty(growable: true);

    final maps = await AppDatabase.instance.database!.query(imagesTable,
        where: '${EntryImageFields.entryId} = ?',
        whereArgs: [entryId],
        orderBy: '${EntryImageFields.imgRank} DESC');

    for (final map in maps) {
      entryImages.add(EntryImage.fromJson(map));
    }

    return entryImages;
  }

  static Future<EntryImage> add(EntryImage entryImage) async {
    final id = await AppDatabase.instance.database!
        .insert(imagesTable, entryImage.toJson());

    return entryImage.copy(id: id);
  }

  static Future<void> remove(EntryImage entryImage) async {
    await AppDatabase.instance.database!.delete(
      imagesTable,
      where: '${EntryImageFields.id} = ?',
      whereArgs: [entryImage.id],
    );
  }

  static Future<void> update(EntryImage image) async {
    await AppDatabase.instance.database!.update(
      imagesTable,
      image.toJson(),
      where: '${EntryImageFields.id} = ?',
      whereArgs: [image.id],
    );
  }
}
