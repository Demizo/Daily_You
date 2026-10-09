// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';
import 'dart:io';

import 'package:daily_you/database/song_storage.dart';
import 'package:daily_you/models/song.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/utils/song_metadata_parser.dart';
import 'package:daily_you/utils/youtube_url_parser.dart';
import 'package:flutter/foundation.dart';

class SongFetchResult {
  final String videoId;
  final String url;
  final String title;
  final String artist;
  final String? coverPath;
  final String? previewUrl;
  final bool isOfflineFallback;

  const SongFetchResult({
    required this.videoId,
    required this.url,
    required this.title,
    required this.artist,
    this.coverPath,
    this.previewUrl,
    this.isOfflineFallback = false,
  });

  EntrySong toEntrySong({required int entryId, DateTime? timeCreate}) {
    return EntrySong(
      entryId: entryId,
      videoId: videoId,
      url: url,
      title: title,
      artist: artist,
      coverPath: coverPath,
      previewUrl: previewUrl,
      timeCreate: timeCreate ?? DateTime.now(),
    );
  }
}

typedef HttpGetHandler = Future<({int statusCode, Uint8List body})?> Function(
    Uri uri);

class SongService {
  static final SongService instance = SongService();

  @visibleForTesting
  HttpGetHandler? httpGetOverride;

  Future<({int statusCode, Uint8List body})?> _httpGet(Uri uri) async {
    if (httpGetOverride != null) {
      return await httpGetOverride!(uri);
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'DailyYou/1.0 (Android)');
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      final bytes = await response.fold<List<int>>(
          <int>[], (buffer, chunk) => buffer..addAll(chunk));
      client.close();
      return (
        statusCode: response.statusCode,
        body: Uint8List.fromList(bytes),
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolves song details from YouTube / YouTube Music URL or shared text.
  /// Fails quietly when network is disabled or offline.
  Future<SongFetchResult> resolveSong(String input) async {
    final videoId = YouTubeUrlParser.extractVideoId(input);
    if (videoId == null) {
      throw ArgumentError('Invalid YouTube / YouTube Music link');
    }

    final normalizedUrl = YouTubeUrlParser.normalizeUrl(videoId);

    // If network disallowed, offline fallback immediately
    if (!NetworkGate.isNetworkAllowed) {
      return SongFetchResult(
        videoId: videoId,
        url: normalizedUrl,
        title: 'YouTube Song ($videoId)',
        artist: 'Unknown Artist',
        coverPath: null,
        previewUrl: null,
        isOfflineFallback: true,
      );
    }

    String title = 'YouTube Song ($videoId)';
    String artist = 'Unknown Artist';
    String? thumbnailUrl;

    // 1. Fetch oEmbed metadata
    try {
      final oembedUri = Uri.parse(
          'https://www.youtube.com/oembed?format=json&url=$normalizedUrl');
      final oembedRes = await _httpGet(oembedUri);
      if (oembedRes != null && oembedRes.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(oembedRes.body)) as Map<String, dynamic>;
        final rawTitle = (jsonMap['title'] as String?) ?? '';
        final authorName = (jsonMap['author_name'] as String?) ?? '';
        thumbnailUrl = jsonMap['thumbnail_url'] as String?;

        final parsed = SongMetadataParser.parse(
          rawTitle: rawTitle,
          authorName: authorName,
        );
        title = parsed.title;
        artist = parsed.artist;
      }
    } catch (_) {
      // oEmbed failed, fallback to video ID thumbnail
    }

    thumbnailUrl ??= YouTubeUrlParser.fallbackThumbnailUrl(videoId);

    // 2. Query iTunes Search API for square cover & previewUrl
    String? previewUrl;
    String? squareArtworkUrl;

    try {
      final itunesUri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent('$artist $title')}&entity=song&limit=5',
      );
      final itunesRes = await _httpGet(itunesUri);
      if (itunesRes != null && itunesRes.statusCode == 200) {
        final itunesJson =
            jsonDecode(utf8.decode(itunesRes.body)) as Map<String, dynamic>;
        final results = itunesJson['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          for (final item in results) {
            final tName = (item['trackName'] as String?)?.toLowerCase() ?? '';
            final aName = (item['artistName'] as String?)?.toLowerCase() ?? '';
            final cleanT = title.toLowerCase();
            final cleanA = artist.toLowerCase();

            // Match verification
            final titleMatches =
                tName.contains(cleanT) || cleanT.contains(tName);
            final artistMatches =
                aName.contains(cleanA) || cleanA.contains(aName);

            if (titleMatches || artistMatches) {
              previewUrl = item['previewUrl'] as String?;
              final art100 = item['artworkUrl100'] as String?;
              if (art100 != null) {
                squareArtworkUrl =
                    art100.replaceAll('100x100bb', '600x600bb');
              }
              break;
            }
          }
        }
      }
    } catch (_) {}

    // 3. Fallback to Deezer for 30s preview if iTunes had no preview
    if (previewUrl == null) {
      try {
        final deezerUri = Uri.parse(
          'https://api.deezer.com/search?q=${Uri.encodeComponent('$artist $title')}&limit=1',
        );
        final deezerRes = await _httpGet(deezerUri);
        if (deezerRes != null && deezerRes.statusCode == 200) {
          final deezerJson =
              jsonDecode(utf8.decode(deezerRes.body)) as Map<String, dynamic>;
          final data = deezerJson['data'] as List<dynamic>?;
          if (data != null && data.isNotEmpty) {
            final first = data.first as Map<String, dynamic>;
            previewUrl = first['preview'] as String?;
          }
        }
      } catch (_) {}
    }

    // 4. Download and cache cover in app storage so it works offline
    String? localCoverPath;
    final coverDownloadUrl = squareArtworkUrl ?? thumbnailUrl;
    try {
      final coverUri = Uri.parse(coverDownloadUrl);
      final coverRes = await _httpGet(coverUri);
      if (coverRes != null &&
          coverRes.statusCode == 200 &&
          coverRes.body.isNotEmpty) {
        final fileName = 'song_${videoId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        localCoverPath = await SongStorage.instance
            .saveCover(fileName, coverRes.body);
      }
    } catch (_) {}

    return SongFetchResult(
      videoId: videoId,
      url: normalizedUrl,
      title: title,
      artist: artist,
      coverPath: localCoverPath,
      previewUrl: previewUrl,
      isOfflineFallback: false,
    );
  }
}
