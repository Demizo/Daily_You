enum MarkdownConstruct {
  bold,
  italic,
  strikethrough,
  highlight,
  header,
  link,
  inlineCode,
  bulletList,
  numberedList,
  blockquote,
  codeBlock,
  horizontalRule,
}

enum MarkdownSpanRole { marker, content }

class MarkdownSpan {
  const MarkdownSpan({
    required this.start,
    required this.end,
    required this.construct,
    required this.role,
    this.headerLevel = 0,
  });

  final int start;
  final int end;
  final MarkdownConstruct construct;
  final MarkdownSpanRole role;
  final int headerLevel;

  @override
  bool operator ==(Object other) =>
      other is MarkdownSpan &&
      other.start == start &&
      other.end == end &&
      other.construct == construct &&
      other.role == role &&
      other.headerLevel == headerLevel;

  @override
  int get hashCode => Object.hash(start, end, construct, role, headerLevel);

  @override
  String toString() {
    final level = headerLevel > 0 ? ' h$headerLevel' : '';
    return '${construct.name}.${role.name}[$start,$end)$level';
  }
}

enum MarkdownBlockKind { blockquote, codeBlock }

class MarkdownBlock {
  const MarkdownBlock({
    required this.start,
    required this.end,
    required this.markerEnd,
    required this.kind,
  });

  final int start;
  final int end;
  final int markerEnd;
  final MarkdownBlockKind kind;

  @override
  bool operator ==(Object other) =>
      other is MarkdownBlock &&
      other.start == start &&
      other.end == end &&
      other.markerEnd == markerEnd &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(start, end, markerEnd, kind);

  @override
  String toString() => '${kind.name}[$start,$end) marker $markerEnd';
}

class MarkdownScan {
  const MarkdownScan({required this.spans, required this.blocks});

  static const MarkdownScan empty = MarkdownScan(spans: [], blocks: []);

  final List<MarkdownSpan> spans;
  final List<MarkdownBlock> blocks;
}

/// Locates the marker and content ranges of Markdown constructs
MarkdownScan scanMarkdown(String text) =>
    text.isEmpty ? MarkdownScan.empty : _MarkdownScanner(text).scan();

class _LineRange {
  const _LineRange(this.start, this.end);

  final int start;
  final int end;
}

class _MarkdownScanner {
  _MarkdownScanner(this.text);

  static final RegExp _fence = RegExp(r'^( {0,3})(`{3,})');
  static final RegExp _horizontalRule = RegExp(r'^ {0,3}([-*_])( *\1){2,} *$');
  static final RegExp _blockquote = RegExp(r'^( {0,3})(>+)( ?)');
  static final RegExp _header = RegExp(r'^( {0,3})(#{1,6})( +|$)');
  static final RegExp _bullet = RegExp(r'^( *)([-*+])( +)');
  static final RegExp _numbered = RegExp(r'^( *)(\d{1,9}[.)])( +)');
  static final RegExp _tableDelimiter =
      RegExp(r'^ *\|? *:?-+:? *(\| *:?-+:? *)*\|? *$');
  static final RegExp _wordCharacter = RegExp(r'[A-Za-z0-9]');

  final String text;
  final List<MarkdownSpan> _spans = [];
  final List<MarkdownBlock> _blocks = [];
  final Set<(String, int)> _unclosedDelimiters = {};

  int? _codeBlockStart;
  int? _quoteStart;
  int? _quoteMarkerEnd;
  int _quoteEnd = 0;
  int _quoteLine = -2;

  MarkdownScan scan() {
    final lines = _splitLines();
    final tableLines = _findTableLines(lines);
    var inCodeBlock = false;

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final body = text.substring(line.start, line.end);

      final fence = _fence.firstMatch(body);
      if (fence != null) {
        final markerStart = line.start + fence.group(1)!.length;
        final markerEnd = markerStart + fence.group(2)!.length;
        _add(markerStart, markerEnd, MarkdownConstruct.codeBlock,
            MarkdownSpanRole.marker);
        if (inCodeBlock) {
          _closeCodeBlock(line.end);
        } else {
          _closeQuote();
          _add(markerEnd, line.end, MarkdownConstruct.codeBlock,
              MarkdownSpanRole.content);
          _codeBlockStart = line.start;
        }
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) {
        _add(line.start, line.end, MarkdownConstruct.codeBlock,
            MarkdownSpanRole.content);
        continue;
      }

      if (tableLines.contains(index)) {
        _closeQuote();
        continue;
      }
      _scanLine(index, line.start, line.end);
    }

    _closeQuote();
    if (lines.isNotEmpty) _closeCodeBlock(lines.last.end);

    _spans.sort((first, second) => first.start != second.start
        ? first.start - second.start
        : second.end - first.end);
    return MarkdownScan(spans: _spans, blocks: _blocks);
  }

  void _closeCodeBlock(int end) {
    final start = _codeBlockStart;
    if (start == null) return;
    _codeBlockStart = null;
    _blocks.add(MarkdownBlock(
      start: start,
      end: end,
      markerEnd: start,
      kind: MarkdownBlockKind.codeBlock,
    ));
  }

  void _closeQuote() {
    final start = _quoteStart;
    if (start == null) return;
    _quoteStart = null;
    _blocks.add(MarkdownBlock(
      start: start,
      end: _quoteEnd,
      markerEnd: _quoteMarkerEnd!,
      kind: MarkdownBlockKind.blockquote,
    ));
  }

  void _openQuote(int lineIndex, int markerStart, int markerEnd, int lineEnd) {
    if (_quoteStart == null || _quoteLine != lineIndex - 1) {
      _closeQuote();
      _quoteStart = markerStart;
      _quoteMarkerEnd = markerEnd;
    }
    _quoteLine = lineIndex;
    _quoteEnd = lineEnd;
  }

  List<_LineRange> _splitLines() {
    final lines = <_LineRange>[];
    var start = 0;
    for (var index = 0; index < text.length; index++) {
      if (text[index] != '\n') continue;
      lines.add(_LineRange(start, index));
      start = index + 1;
    }
    lines.add(_LineRange(start, text.length));
    return lines;
  }

  Set<int> _findTableLines(List<_LineRange> lines) {
    final tableLines = <int>{};
    for (var index = 1; index < lines.length; index++) {
      final body = text.substring(lines[index].start, lines[index].end);
      if (!body.contains('|') || !_tableDelimiter.hasMatch(body)) continue;

      final header =
          text.substring(lines[index - 1].start, lines[index - 1].end);
      if (!header.contains('|')) continue;

      tableLines.add(index - 1);
      tableLines.add(index);
      for (var row = index + 1; row < lines.length; row++) {
        final rowBody = text.substring(lines[row].start, lines[row].end);
        if (!rowBody.contains('|')) break;
        tableLines.add(row);
      }
    }
    return tableLines;
  }

  void _scanLine(int lineIndex, int start, int end) {
    if (end <= start) {
      _closeQuote();
      return;
    }

    var contentStart = start;
    final quote = _blockquote.firstMatch(text.substring(start, end));
    if (quote == null) {
      _closeQuote();
    } else {
      final markerStart = start + quote.group(1)!.length;
      final markerEnd = markerStart + quote.group(2)!.length;
      _add(markerStart, markerEnd, MarkdownConstruct.blockquote,
          MarkdownSpanRole.marker);
      _openQuote(lineIndex, markerStart, markerEnd, end);
      contentStart = markerEnd + quote.group(3)!.length;
      _add(contentStart, end, MarkdownConstruct.blockquote,
          MarkdownSpanRole.content);
    }

    final body = text.substring(contentStart, end);

    if (_horizontalRule.hasMatch(body)) {
      final leading = body.length - body.trimLeft().length;
      final trailing = body.length - body.trimRight().length;
      _add(contentStart + leading, end - trailing,
          MarkdownConstruct.horizontalRule, MarkdownSpanRole.marker);
      return;
    }

    final header = _header.firstMatch(body);
    if (header != null) {
      final level = header.group(2)!.length;
      final markerStart = contentStart + header.group(1)!.length;
      final markerEnd = markerStart + level;
      _add(markerStart, markerEnd, MarkdownConstruct.header,
          MarkdownSpanRole.marker, level);
      final textStart = markerEnd + header.group(3)!.length;
      _add(textStart, end, MarkdownConstruct.header, MarkdownSpanRole.content,
          level);
      _scanInline(textStart, end);
      return;
    }

    final bullet = _bullet.firstMatch(body);
    final numbered = bullet == null ? _numbered.firstMatch(body) : null;
    final list = bullet ?? numbered;
    if (list != null) {
      final markerStart = contentStart + list.group(1)!.length;
      final markerEnd = markerStart + list.group(2)!.length;
      _add(
          markerStart,
          markerEnd,
          bullet != null
              ? MarkdownConstruct.bulletList
              : MarkdownConstruct.numberedList,
          MarkdownSpanRole.marker);
      _scanInline(markerEnd + list.group(3)!.length, end);
      return;
    }

    _scanInline(contentStart, end);
  }

  void _scanInline(int start, int end) {
    var index = start;
    while (index < end) {
      final consumed = switch (text[index]) {
        '`' => _scanInlineCode(index, end),
        '[' => _scanLink(index, end),
        '*' || '_' || '~' || '=' => _scanEmphasis(index, end),
        _ => 0,
      };
      index += consumed > 0 ? consumed : 1;
    }
  }

  int _scanInlineCode(int start, int end) {
    final openEnd = _runEnd(start, end, '`');
    final ticks = '`' * (openEnd - start);

    var search = openEnd;
    while (search < end) {
      final close = text.indexOf(ticks, search);
      if (close < 0 || close + ticks.length > end) return 0;

      final closeEnd = _runEnd(close, end, '`');
      if (closeEnd - close != ticks.length) {
        search = closeEnd;
        continue;
      }

      _add(start, openEnd, MarkdownConstruct.inlineCode,
          MarkdownSpanRole.marker);
      _add(openEnd, close, MarkdownConstruct.inlineCode,
          MarkdownSpanRole.content);
      _add(close, closeEnd, MarkdownConstruct.inlineCode,
          MarkdownSpanRole.marker);
      return closeEnd - start;
    }
    return 0;
  }

  int _scanLink(int start, int end) {
    var depth = 0;
    var close = -1;
    for (var index = start; index < end; index++) {
      if (text[index] == '[') depth++;
      if (text[index] != ']') continue;
      depth--;
      if (depth == 0) {
        close = index;
        break;
      }
    }
    if (close < 0 || close + 1 >= end || text[close + 1] != '(') return 0;

    final closingParenthesis = text.indexOf(')', close + 2);
    if (closingParenthesis < 0 || closingParenthesis >= end) return 0;

    _add(start, start + 1, MarkdownConstruct.link, MarkdownSpanRole.marker);
    _add(start + 1, close, MarkdownConstruct.link, MarkdownSpanRole.content);
    _scanInline(start + 1, close);
    _add(close, closingParenthesis + 1, MarkdownConstruct.link,
        MarkdownSpanRole.marker);
    return closingParenthesis + 1 - start;
  }

  int _scanEmphasis(int start, int end) {
    final character = text[start];
    final runLength = _runEnd(start, end, character) - start;

    final MarkdownConstruct construct;
    final int delimiterLength;
    if (character == '~') {
      if (runLength != 2) return 0;
      construct = MarkdownConstruct.strikethrough;
      delimiterLength = 2;
    } else if (character == '=') {
      if (runLength != 2) return 0;
      construct = MarkdownConstruct.highlight;
      delimiterLength = 2;
    } else if (runLength >= 2) {
      construct = MarkdownConstruct.bold;
      delimiterLength = 2;
    } else {
      construct = MarkdownConstruct.italic;
      delimiterLength = 1;
    }

    final openEnd = start + runLength;
    if (openEnd >= end || _isWhitespace(text[openEnd])) return 0;
    if (character == '_' && start > 0 && _isWordCharacter(text[start - 1])) {
      return 0;
    }

    final delimiter = character * delimiterLength;
    if (_unclosedDelimiters.contains((delimiter, end))) return 0;

    var search = openEnd;
    while (search < end) {
      final close = text.indexOf(delimiter, search);
      if (close < 0 || close + delimiterLength > end) break;

      final closeEnd = _runEnd(close, end, character);
      final blocked = close == openEnd ||
          _isWhitespace(text[close - 1]) ||
          (character == '_' &&
              closeEnd < end &&
              _isWordCharacter(text[closeEnd]));
      if (blocked) {
        search = close + 1;
        continue;
      }

      _add(start, openEnd, construct, MarkdownSpanRole.marker);
      _add(openEnd, close, construct, MarkdownSpanRole.content);
      _scanInline(openEnd, close);
      _add(close, closeEnd, construct, MarkdownSpanRole.marker);
      return closeEnd - start;
    }
    _unclosedDelimiters.add((delimiter, end));
    return 0;
  }

  int _runEnd(int start, int end, String character) {
    var index = start;
    while (index < end && text[index] == character) {
      index++;
    }
    return index;
  }

  bool _isWhitespace(String character) => character.trim().isEmpty;

  bool _isWordCharacter(String character) => _wordCharacter.hasMatch(character);

  void _add(
      int start, int end, MarkdownConstruct construct, MarkdownSpanRole role,
      [int headerLevel = 0]) {
    if (end <= start) return;
    _spans.add(MarkdownSpan(
      start: start,
      end: end,
      construct: construct,
      role: role,
      headerLevel: headerLevel,
    ));
  }
}
