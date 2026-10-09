// Behavior based on DenserMeerkat/June (GPL-3.0)

class YouTubeUrlParser {
  static final RegExp _videoRegex = RegExp(
    r'(?:https?:\/\/)?(?:(?:music\.|www\.)?youtube\.com\/(?:watch\?.*v=|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );

  /// Extracts the 11-character video ID from a YouTube / YouTube Music URL or free-text share intent.
  /// Drops tracking parameters like `si` and `feature`.
  static String? extractVideoId(String input) {
    final match = _videoRegex.firstMatch(input);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  /// Normalizes a video ID or URL to https://www.youtube.com/watch?v=ID
  static String normalizeUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Constructs the YouTube Music URL: https://music.youtube.com/watch?v=ID
  static String musicUrl(String videoId) {
    return 'https://music.youtube.com/watch?v=$videoId';
  }

  /// Constructs fallback thumbnail URL: https://img.youtube.com/vi/ID/hqdefault.jpg
  static String fallbackThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
