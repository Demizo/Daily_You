import 'dart:io';

import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  const secret = 'super secret message';
  late Directory work;
  late String archive;

  setUp(() async {
    work = await Directory.systemTemp.createTemp('zip_utils_password');
    archive = join(work.path, 'backup.zip');
    await File(join(work.path, 'daily_you.db')).writeAsString(secret);
  });

  tearDown(() => work.delete(recursive: true));

  Future<void> compress({String? password}) =>
      ZipUtils.compress(archive, [join(work.path, 'daily_you.db')], [],
          password: password);

  Future<String> extractDatabase({String? password}) async {
    final destination = await work.createTemp('out');
    await ZipUtils.extract(archive, destination.path, password: password);
    return File(join(destination.path, 'daily_you.db')).readAsString();
  }

  test('an unprotected backup round trips', () async {
    await compress();
    expect(await extractDatabase(), secret);
  });

  test('a protected backup round trips with its password', () async {
    await compress(password: 'dolphin');
    expect(await extractDatabase(password: 'dolphin'), secret);
  });

  test('a protected backup does not carry entry text in the clear', () async {
    await compress(password: 'dolphin');
    final bytes = await File(archive).readAsBytes();
    expect(String.fromCharCodes(bytes).contains(secret), isFalse);
  });

  test('a protected backup refuses the wrong password', () async {
    await compress(password: 'dolphin');
    expect(extractDatabase(password: 'wrong'), throwsA(anything));
  });

  test('a protected backup refuses no password at all', () async {
    await compress(password: 'dolphin');
    expect(extractDatabase(), throwsA(anything));
  });
}
