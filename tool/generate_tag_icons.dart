// Generates lib/utils/generated/tag_icon_registry.dart from
// lib/utils/tag_icons.yaml. Run with:
//   dart run tool/generate_tag_icons.dart

import 'dart:convert';
import 'dart:io';

import 'package:mustache_template/mustache_template.dart';
import 'package:yaml/yaml.dart';

const _sourcePath = 'lib/utils/tag_icons.yaml';
const _templatePath = 'tool/templates/tag_icon_registry.mustache';
const _arbPath = 'lib/l10n/intl_en.arb';
const _outputPath = 'lib/utils/generated/tag_icon_registry.dart';

final _identifierPattern = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

String _constantNameFor(String key) {
  final words = key.split('_');
  return words.first +
      words
          .skip(1)
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join();
}

void main() {
  final sourceFile = File(_sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Error: $_sourcePath not found.');
    exit(1);
  }

  final yamlDoc = loadYaml(sourceFile.readAsStringSync());
  final rawGroups = (yamlDoc as YamlMap)['groups'] as YamlList;

  final arbKeys =
      (jsonDecode(File(_arbPath).readAsStringSync()) as Map<String, dynamic>)
          .keys
          .toSet();

  final errors = <String>[];
  final seenGroupIds = <String>{};
  final seenIconKeys = <String, String>{}; // key -> owning group id
  final seenIcons = <String, String>{}; // icon member -> owning group id
  final seenConstantNames = <String, String>{}; // constant name -> key

  final groups = <Map<String, Object?>>[];

  for (final rawGroup in rawGroups) {
    final group = rawGroup as YamlMap;
    final id = group['id'] as String;
    final l10nKey = group['l10nKey'] as String;

    if (!_identifierPattern.hasMatch(id)) {
      errors.add('Group id "$id" is not a valid Dart identifier.');
    }
    if (!seenGroupIds.add(id)) {
      errors.add('Duplicate group id "$id".');
    }
    if (!arbKeys.contains(l10nKey)) {
      errors.add('Group "$id" references l10nKey "$l10nKey", which does '
          'not exist in $_arbPath.');
    }

    final icons = <Map<String, Object?>>[];
    for (final rawIcon in group['icons'] as YamlList) {
      final icon = rawIcon as YamlMap;
      final key = icon['key'] as String;
      final iconMember = icon['icon'] as String;

      if (!_identifierPattern.hasMatch(iconMember)) {
        errors.add('Icon member "$iconMember" (key "$key", group "$id") is '
            'not a valid Dart identifier.');
      }

      final existingKeyOwner = seenIconKeys[key];
      if (existingKeyOwner != null) {
        errors.add('Duplicate icon key "$key" in group "$id" '
            '(already used in group "$existingKeyOwner").');
      } else {
        seenIconKeys[key] = id;
      }

      final existingIconOwner = seenIcons[iconMember];
      if (existingIconOwner != null) {
        errors.add('Duplicate icon "Icons.$iconMember" for key "$key" in '
            'group "$id" (already used in group "$existingIconOwner").');
      } else {
        seenIcons[iconMember] = id;
      }

      final constantName = _constantNameFor(key);
      final existingConstantOwner = seenConstantNames[constantName];
      if (existingConstantOwner != null) {
        errors.add('Icon key "$key" generates the same constant name '
            '"$constantName" as key "$existingConstantOwner".');
      } else {
        seenConstantNames[constantName] = key;
      }

      icons.add({'key': key, 'icon': iconMember, 'constantName': constantName});
    }

    groups.add({'id': id, 'l10nKey': l10nKey, 'icons': icons});
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Found ${errors.length} problem(s) in $_sourcePath:');
    for (final error in errors) {
      stderr.writeln('  - $error');
    }
    exit(1);
  }

  final template =
      Template(File(_templatePath).readAsStringSync(), htmlEscapeValues: false);
  final output = template.renderString({'groups': groups});

  final outputFile = File(_outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(output);

  final format = Process.runSync('dart', ['format', _outputPath]);
  if (format.exitCode != 0) {
    stderr.writeln(format.stdout);
    stderr.writeln(format.stderr);
    exit(1);
  }

  stdout.writeln(
      'Generated $_outputPath from $_sourcePath (${groups.length} groups, '
      '${seenIconKeys.length} icons).');
}
