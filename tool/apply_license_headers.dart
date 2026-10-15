// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

// Adds the license header to every Dart and Kotlin source file in the app and
// the local packages. Run from the repository root with:
//   dart run tool/apply_license_headers.dart          (writes headers)
//   dart run tool/apply_license_headers.dart --check  (lists files that differ)

import 'dart:io';

const _headerLines = [
  '// Copyright (C) 2026 Demizo and contributors',
  '// SPDX-License-Identifier: GPL-3.0-only',
  '// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.',
];

const _sourceRoots = ['lib', 'test', 'tool', 'packages', 'android/app/src'];
const _sourceExtensions = ['.dart', '.kt'];
const _generatedMarker = 'GENERATED CODE';

Future<List<String>> _sourcePaths() async {
  final result = await Process.run('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
    '--',
    ..._sourceRoots,
  ]);
  if (result.exitCode != 0) {
    stderr.writeln('Error: git ls-files failed: ${result.stderr}');
    exit(1);
  }
  return (result.stdout as String)
      .split('\n')
      .where((path) => _sourceExtensions.any(path.endsWith))
      .where((path) => !path.split('/').contains('generated'))
      .where((path) => File(path).existsSync())
      .toList();
}

String? _withHeader(String content) {
  final lines = content.split('\n');
  final shebang = lines.isNotEmpty && lines.first.startsWith('#!');
  final bodyStart = shebang ? 1 : 0;

  var commentEnd = bodyStart;
  while (commentEnd < lines.length && lines[commentEnd].startsWith('//')) {
    commentEnd++;
  }
  final leadingComment = lines.sublist(bodyStart, commentEnd);

  if (leadingComment.any((line) => line.contains(_generatedMarker))) {
    return null;
  }

  final hasHeader =
      leadingComment.any((line) => line.contains('SPDX-License-Identifier'));
  final remainder =
      hasHeader ? lines.sublist(commentEnd) : lines.sublist(bodyStart);
  final needsBlankLine = remainder.isNotEmpty && remainder.first.isNotEmpty;

  return [
    if (shebang) lines.first,
    ..._headerLines,
    if (needsBlankLine) '',
    ...remainder,
  ].join('\n');
}

Future<void> main(List<String> arguments) async {
  final checkOnly = arguments.contains('--check');
  final outdated = <String>[];

  for (final path in await _sourcePaths()) {
    final file = File(path);
    final content = file.readAsStringSync();
    final updated = _withHeader(content);
    if (updated == null || updated == content) continue;
    outdated.add(path);
    if (!checkOnly) file.writeAsStringSync(updated);
  }

  if (outdated.isEmpty) {
    stdout.writeln('All source files have the license header.');
    return;
  }

  final verb = checkOnly ? 'need the license header' : 'updated';
  stdout.writeln('${outdated.length} files $verb:');
  outdated.forEach(stdout.writeln);
  if (checkOnly) exit(1);
}
