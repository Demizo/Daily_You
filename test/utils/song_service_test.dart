// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/song_storage.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/utils/song_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('SongService', () {
    late InMemoryFileStore memoryStore;

    setUp(() {
      memoryStore = InMemoryFileStore();
      SongStorage.instance.overrideStore(memoryStore);
      NetworkGate.debugOverrideCompiledIn = true;
    });

    tearDown(() {
      SongStorage.instance.clearStoreOverride();
      SongService.instance.httpGetOverride = null;
      NetworkGate.debugOverrideCompiledIn = null;
    });

    test('throws NetworkDisabledException when network is disabled', () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, false);

      expect(
        () => SongService.instance.resolveSong(
          'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        throwsA(isA<NetworkDisabledException>()),
      );
    });

    test('returns offline fallback without fabricated info when allowOfflineFallback is true', () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, false);

      final result = await SongService.instance.resolveSong(
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
        allowOfflineFallback: true,
      );

      expect(result.isOfflineFallback, isTrue);
      expect(result.videoId, 'dQw4w9WgXcQ');
      expect(result.title, isEmpty);
      expect(result.artist, isEmpty);
      expect(result.album, isNull);
      expect(result.coverPath, isNull);
      expect(result.previewUrl, isNull);
    });

    test('resolves metadata, itunes preview, and caches cover when network allowed',
        () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, true);

      SongService.instance.httpGetOverride = (uri) async {
        final urlStr = uri.toString();
        if (urlStr.contains('youtube.com/oembed')) {
          final jsonStr = jsonEncode({
            'title': 'Never Gonna Give You Up (Official Music Video)',
            'author_name': 'Rick Astley',
            'thumbnail_url': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          });
          return (
            statusCode: 200,
            body: Uint8List.fromList(utf8.encode(jsonStr)),
          );
        } else if (urlStr.contains('itunes.apple.com/search')) {
          final jsonStr = jsonEncode({
            'resultCount': 1,
            'results': [
              {
                'trackName': 'Never Gonna Give You Up',
                'artistName': 'Rick Astley',
                'collectionName': 'Whenever You Need Somebody',
                'previewUrl': 'https://audio-ssl.itunes.apple.com/preview.m4a',
                'artworkUrl100': 'https://is1-ssl.mzstatic.com/100x100bb.jpg',
              }
            ]
          });
          return (
            statusCode: 200,
            body: Uint8List.fromList(utf8.encode(jsonStr)),
          );
        } else if (urlStr.contains('mzstatic.com') ||
            urlStr.contains('ytimg.com')) {
          // Fake image bytes
          return (
            statusCode: 200,
            body: Uint8List.fromList([1, 2, 3, 4, 5]),
          );
        }
        return null;
      };

      final result = await SongService.instance.resolveSong(
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ&si=tracking',
      );

      expect(result.isOfflineFallback, isFalse);
      expect(result.videoId, 'dQw4w9WgXcQ');
      expect(result.title, 'Never Gonna Give You Up');
      expect(result.artist, 'Rick Astley');
      expect(result.album, 'Whenever You Need Somebody');
      expect(
          result.previewUrl, 'https://audio-ssl.itunes.apple.com/preview.m4a');
      expect(result.coverPath, isNotNull);

      // Verify cover was saved to storage
      final savedBytes =
          await SongStorage.instance.getBytes(result.coverPath!);
      expect(savedBytes, [1, 2, 3, 4, 5]);
    });

    test('falls back to Deezer when iTunes search has no results', () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, true);

      SongService.instance.httpGetOverride = (uri) async {
        final urlStr = uri.toString();
        if (urlStr.contains('youtube.com/oembed')) {
          final jsonStr = jsonEncode({
            'title': 'Yellow',
            'author_name': 'Coldplay - Topic',
            'thumbnail_url': 'https://i.ytimg.com/vi/12345/hqdefault.jpg',
          });
          return (
            statusCode: 200,
            body: Uint8List.fromList(utf8.encode(jsonStr)),
          );
        } else if (urlStr.contains('itunes.apple.com/search')) {
          return (
            statusCode: 200,
            body: Uint8List.fromList(utf8.encode(jsonEncode({'results': []}))),
          );
        } else if (urlStr.contains('api.deezer.com/search')) {
          final jsonStr = jsonEncode({
            'data': [
              {
                'title': 'Yellow',
                'artist': {'name': 'Coldplay'},
                'preview': 'https://cdns-preview.dzcdn.net/stream/yellow.mp3',
              }
            ]
          });
          return (
            statusCode: 200,
            body: Uint8List.fromList(utf8.encode(jsonStr)),
          );
        } else if (urlStr.contains('ytimg.com')) {
          return (
            statusCode: 200,
            body: Uint8List.fromList([10, 20, 30]),
          );
        }
        return null;
      };

      final result = await SongService.instance.resolveSong(
        'https://youtu.be/12345678901',
      );

      expect(result.artist, 'Coldplay');
      expect(result.title, 'Yellow');
      expect(result.previewUrl,
          'https://cdns-preview.dzcdn.net/stream/yellow.mp3');
      expect(result.coverPath, isNotNull);
    });
  });
}
