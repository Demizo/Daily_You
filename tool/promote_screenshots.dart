import 'dart:io';

const _defaultStagingRoot = 'build/screenshots_staging';
const _fastlaneRoot = 'fastlane/metadata/android';
const _screenshotsSubPath = 'images/phoneScreenshots';

void main(List<String> arguments) {
  final stagingRoot = _stagingRootFrom(arguments);
  final stagingDirectory = Directory(stagingRoot);
  if (!stagingDirectory.existsSync()) {
    stderr.writeln('No staged directory at $stagingRoot, nothing to promote');
    exit(1);
  }

  var promotedLocales = 0;
  var promotedFiles = 0;

  for (final entity in stagingDirectory.listSync()) {
    if (entity is! Directory) continue;
    final fastlaneLocale =
        entity.uri.pathSegments.where((s) => s.isNotEmpty).last;

    final sourceDirectory = Directory('${entity.path}/$_screenshotsSubPath');
    if (!sourceDirectory.existsSync()) continue;

    final destinationDirectory =
        Directory('$_fastlaneRoot/$fastlaneLocale/$_screenshotsSubPath');
    destinationDirectory.createSync(recursive: true);

    var copiedForLocale = 0;
    for (final file in sourceDirectory.listSync().whereType<File>()) {
      if (!file.path.toLowerCase().endsWith('.png')) continue;
      final destinationPath =
          '${destinationDirectory.path}/${file.uri.pathSegments.last}';
      file.copySync(destinationPath);
      copiedForLocale += 1;
    }

    if (copiedForLocale > 0) {
      stdout.writeln('Promoted $copiedForLocale screenshot(s) to '
          '$_fastlaneRoot/$fastlaneLocale/$_screenshotsSubPath');
      promotedLocales += 1;
      promotedFiles += copiedForLocale;
    }
  }

  stdout.writeln(
      'Done: $promotedFiles screenshot(s) across $promotedLocales locale(s)');
}

String _stagingRootFrom(List<String> arguments) {
  const prefix = '--staging=';
  for (final argument in arguments) {
    if (argument.startsWith(prefix)) return argument.substring(prefix.length);
  }
  return _defaultStagingRoot;
}
