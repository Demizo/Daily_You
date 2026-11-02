// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:collection';

import 'package:markdown/markdown.dart' as m;

class _PlainTextDocument extends m.Document {
  _PlainTextDocument({
    super.extensionSet,
    super.inlineSyntaxes,
    super.blockSyntaxes,
    super.encodeHtml,
  });

  static final _markup = RegExp(
    r'[\\*_`~=\[\]<&@]| \n|://|www\.|:[a-z0-9_+-]+:',
    caseSensitive: false,
  );

  @override
  List<m.Node> parseInline(String text) =>
      _markup.hasMatch(text) ? super.parseInline(text) : [m.Text(text)];
}

class MarkdownParser {
  MarkdownParser({
    this.inlineSyntaxes = const [],
    this.blockSyntaxes = const [],
    required this.splitRegExp,
  });

  static const int _maxCachedDocuments = 256;
  static final LinkedHashMap<String, _CachedDocument> _cache =
      LinkedHashMap<String, _CachedDocument>();

  final Iterable<m.InlineSyntax> inlineSyntaxes;
  final Iterable<m.BlockSyntax> blockSyntaxes;
  final RegExp splitRegExp;

  late final String _signature = [
    for (final syntax in inlineSyntaxes) '${syntax.runtimeType}',
    for (final syntax in blockSyntaxes) '${syntax.runtimeType}',
    splitRegExp.pattern,
  ].join('|');

  List<m.Node> parse(String data) {
    final cached = _cache.remove(data);
    if (cached != null && cached.signature == _signature) {
      _cache[data] = cached;
      return cached.nodes;
    }
    final document = _PlainTextDocument(
      extensionSet: m.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
      inlineSyntaxes: inlineSyntaxes,
      blockSyntaxes: blockSyntaxes,
    );
    final nodes = document.parseLines(data.split(splitRegExp));
    _cache[data] = _CachedDocument(_signature, nodes);
    if (_cache.length > _maxCachedDocuments) {
      _cache.remove(_cache.keys.first);
    }
    return nodes;
  }
}

class _CachedDocument {
  const _CachedDocument(this.signature, this.nodes);

  final String signature;
  final List<m.Node> nodes;
}
