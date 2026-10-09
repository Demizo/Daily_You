// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:daily_you/database/song_storage.dart';
import 'package:daily_you/models/song.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:path/path.dart' as p;

class AudioImportHelper {
  static String computeHash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  static EntrySong createSongFromBytes({
    required String fileName,
    required Uint8List bytes,
    String? customTitle,
    String? customArtist,
    int previewStartMs = 0,
    int? previewEndMs = 30000,
  }) {
    final hash = computeHash(bytes);
    final ext = p.extension(fileName).isNotEmpty ? p.extension(fileName) : '.mp3';
    final storageFileName = 'audio_${hash.substring(0, 16)}$ext';

    final rawName = p.basenameWithoutExtension(fileName);
    String title = customTitle ?? rawName;
    String artist = customArtist ?? 'Local Audio';
    if (customTitle == null && rawName.contains(' - ')) {
      final parts = rawName.split(' - ');
      artist = parts[0].trim();
      title = parts.sublist(1).join(' - ').trim();
    }

    return EntrySong(
      entryId: -1,
      videoId: 'loc_${hash.substring(0, 8)}',
      url: 'file://$storageFileName',
      title: title,
      artist: artist,
      previewUrl: storageFileName,
      previewStartMs: previewStartMs,
      previewEndMs: previewEndMs,
      timeCreate: DateTime.now(),
    );
  }

  static Future<EntrySong?> pickAndImportLocalAudio() async {
    final picked = await StoragePicker.pickFile(
      allowedExtensions: ['mp3', 'm4a', 'wav', 'ogg', 'aac', 'flac'],
      mimeTypes: ['audio/*'],
    );
    if (picked == null) return null;

    final bytes = await picked.readBytes();
    if (bytes == null) return null;

    final fileName = StoragePicker.displayName(picked.uri);
    final song = createSongFromBytes(
      fileName: fileName,
      bytes: bytes,
    );

    // Save to song storage with hash deduplication
    final destFileName = p.basename(song.url.replaceFirst('file://', ''));
    await SongStorage.instance.saveCover(destFileName, bytes);

    return song;
  }
}
