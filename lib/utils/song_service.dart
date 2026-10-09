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
  final String? album;
  final String? coverPath;
  final String? previewUrl;
  final bool isOfflineFallback;

  const SongFetchResult({
    required this.videoId,
    required this.url,
    required this.title,
    required this.artist,
    this.album,
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
      album: album,
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

  Future<({int statusCode, Uint8List body})?> _httpGet(Uri uri,
      {String? userAgent}) async {
    if (httpGetOverride != null) {
      return await httpGetOverride!(uri);
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        userAgent ??
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );
      final response =
          await request.close().timeout(const Duration(seconds: 10));
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
  /// Throws [NetworkDisabledException] if network access is disabled in settings.
  Future<SongFetchResult> resolveSong(String input,
      {bool allowOfflineFallback = false}) async {
    final videoId = YouTubeUrlParser.extractVideoId(input);
    if (videoId == null) {
      throw ArgumentError('Invalid YouTube or YouTube Music link');
    }

    final normalizedUrl = YouTubeUrlParser.normalizeUrl(videoId);

    if (!NetworkGate.isNetworkAllowed) {
      if (allowOfflineFallback) {
        return SongFetchResult(
          videoId: videoId,
          url: normalizedUrl,
          title: '',
          artist: '',
          album: null,
          coverPath: null,
          previewUrl: null,
          isOfflineFallback: true,
        );
      }
      throw const NetworkDisabledException(
          'Network access is disabled in settings. Please enable network access to fetch online song details.');
    }

    String title = '';
    String artist = '';
    String? album;
    String? thumbnailUrl;
    String? previewUrl;
    String? squareArtworkUrl;

    // 1. Try song.link (Odesli) scraper for accurate music metadata
    try {
      final songLinkUri = Uri.parse('https://song.link/$normalizedUrl');
      final songLinkRes = await _httpGet(songLinkUri);
      if (songLinkRes != null && songLinkRes.statusCode == 200) {
        final html = utf8.decode(songLinkRes.body);
        final match = RegExp(r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>',
                dotAll: true)
            .firstMatch(html);
        if (match != null) {
          final nextData = jsonDecode(match.group(1)!) as Map<String, dynamic>;
          final pageData = nextData['props']?['pageProps']?['pageData']
              as Map<String, dynamic>?;
          final entityData = pageData?['entityData'] as Map<String, dynamic>?;
          if (entityData != null) {
            title = (entityData['title'] as String?)?.trim() ?? '';
            artist = (entityData['artistName'] as String?)?.trim() ?? '';
            thumbnailUrl = entityData['thumbnailUrl'] as String?;
          }
        }
      }
    } catch (_) {}

    // 2. Fallback to YouTube oEmbed if title not resolved
    if (title.isEmpty) {
      try {
        final oembedUri = Uri.parse(
            'https://www.youtube.com/oembed?format=json&url=$normalizedUrl');
        final oembedRes = await _httpGet(oembedUri);
        if (oembedRes != null && oembedRes.statusCode == 200) {
          final jsonMap =
              jsonDecode(utf8.decode(oembedRes.body)) as Map<String, dynamic>;
          final rawTitle = (jsonMap['title'] as String?) ?? '';
          final authorName = (jsonMap['author_name'] as String?) ?? '';
          thumbnailUrl ??= jsonMap['thumbnail_url'] as String?;

          final parsed = SongMetadataParser.parse(
            rawTitle: rawTitle,
            authorName: authorName,
          );
          title = parsed.title;
          artist = parsed.artist;
        }
      } catch (_) {}
    }

    thumbnailUrl ??= YouTubeUrlParser.fallbackThumbnailUrl(videoId);

    // 3. Query iTunes Search API for album name, verified preview, and square cover
    if (artist.isNotEmpty || title.isNotEmpty) {
      try {
        final query = '$artist $title'.trim();
        final itunesUri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=5',
        );
        final itunesRes = await _httpGet(itunesUri);
        if (itunesRes != null && itunesRes.statusCode == 200) {
          final itunesJson =
              jsonDecode(utf8.decode(itunesRes.body)) as Map<String, dynamic>;
          final results = itunesJson['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            for (final item in results) {
              final tName =
                  (item['trackName'] as String?)?.toLowerCase() ?? '';
              final aName =
                  (item['artistName'] as String?)?.toLowerCase() ?? '';
              final cleanT = title.toLowerCase();
              final cleanA = artist.toLowerCase();

              final titleMatches = cleanT.isEmpty ||
                  tName.contains(cleanT) ||
                  cleanT.contains(tName);
              final artistMatches = cleanA.isEmpty ||
                  aName.contains(cleanA) ||
                  cleanA.contains(aName);

              if (titleMatches || artistMatches) {
                if (title.isEmpty && item['trackName'] != null) {
                  title = item['trackName'] as String;
                }
                if (artist.isEmpty && item['artistName'] != null) {
                  artist = item['artistName'] as String;
                }
                album = item['collectionName'] as String?;
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
    }

    // 4. Fallback to Deezer for preview and album if needed
    if (previewUrl == null || album == null) {
      try {
        final query = '$artist $title'.trim();
        final deezerUri = Uri.parse(
          'https://api.deezer.com/search?q=${Uri.encodeComponent(query)}&limit=1',
        );
        final deezerRes = await _httpGet(deezerUri);
        if (deezerRes != null && deezerRes.statusCode == 200) {
          final deezerJson =
              jsonDecode(utf8.decode(deezerRes.body)) as Map<String, dynamic>;
          final data = deezerJson['data'] as List<dynamic>?;
          if (data != null && data.isNotEmpty) {
            final first = data.first as Map<String, dynamic>;
            previewUrl ??= first['preview'] as String?;
            album ??= first['album']?['title'] as String?;
            squareArtworkUrl ??= first['album']?['cover_big'] as String?;
          }
        }
      } catch (_) {}
    }

    // 5. Download and cache cover in app storage so it works offline
    String? localCoverPath;
    final coverDownloadUrl = squareArtworkUrl ?? thumbnailUrl;
    if (coverDownloadUrl.isNotEmpty) {
      try {
        final coverUri = Uri.parse(coverDownloadUrl);
        final coverRes = await _httpGet(coverUri);
        if (coverRes != null &&
            coverRes.statusCode == 200 &&
            coverRes.body.isNotEmpty) {
          final fileName =
              'song_${videoId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          localCoverPath = await SongStorage.instance
              .saveCover(fileName, coverRes.body);
        }
      } catch (_) {}
    }

    if (title.isEmpty && artist.isEmpty) {
      throw Exception('Could not fetch song metadata. Please enter details manually.');
    }

    return SongFetchResult(
      videoId: videoId,
      url: normalizedUrl,
      title: title,
      artist: artist,
      album: album,
      coverPath: localCoverPath,
      previewUrl: previewUrl,
      isOfflineFallback: false,
    );
  }
}
