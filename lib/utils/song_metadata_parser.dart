// Behavior based on DenserMeerkat/June (GPL-3.0)

class ParsedSongMetadata {
  final String title;
  final String artist;

  const ParsedSongMetadata({required this.title, required this.artist});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedSongMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist;

  @override
  int get hashCode => title.hashCode ^ artist.hashCode;

  @override
  String toString() => 'ParsedSongMetadata(title: $title, artist: $artist)';
}

class SongMetadataParser {
  static final RegExp _noiseRegex = RegExp(
    r'\s*[\[\(](?:official(?:\s+(?:music\s+)?video)?|audio|lyrics?|visualizer|hd|4k|official\s+audio)[\]\)]',
    caseSensitive: false,
  );

  static final RegExp _topicRegex = RegExp(
    r'\s*-\s*Topic$',
    caseSensitive: false,
  );

  /// Parses title and artist from rawTitle and authorName according to URS.md rules.
  static ParsedSongMetadata parse({
    required String rawTitle,
    required String authorName,
  }) {
    final cleanAuthor = authorName.trim();
    final cleanTitle = rawTitle.trim();

    // If author ends with " - Topic", artist is author without suffix and title is clean
    if (_topicRegex.hasMatch(cleanAuthor)) {
      final artist = cleanAuthor.replaceFirst(_topicRegex, '').trim();
      return ParsedSongMetadata(title: cleanTitle, artist: artist);
    }

    // Strip video noise like (Official Video), (Audio), [Lyrics]
    String strippedTitle = cleanTitle.replaceAll(_noiseRegex, '').trim();

    // Check for "Artist - Title" or "Artist — Title"
    if (strippedTitle.contains(' - ')) {
      final parts = strippedTitle.split(' - ');
      final artist = parts[0].trim();
      final title = parts.sublist(1).join(' - ').trim();
      if (artist.isNotEmpty && title.isNotEmpty) {
        return ParsedSongMetadata(title: title, artist: artist);
      }
    } else if (strippedTitle.contains(' — ')) {
      final parts = strippedTitle.split(' — ');
      final artist = parts[0].trim();
      final title = parts.sublist(1).join(' — ').trim();
      if (artist.isNotEmpty && title.isNotEmpty) {
        return ParsedSongMetadata(title: title, artist: artist);
      }
    }

    // Fallback: title is strippedTitle, artist is authorName
    return ParsedSongMetadata(
      title: strippedTitle.isNotEmpty ? strippedTitle : cleanTitle,
      artist: cleanAuthor,
    );
  }
}
