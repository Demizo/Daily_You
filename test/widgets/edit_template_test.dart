// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/template_dao.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  late Database database;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
    await TemplatesProvider.instance.load();
  });
  tearDown(() async {
    TemplatesProvider.instance.templates.clear();
    AppDatabase.instance.database = null;
    await database.close();
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EditTemplate(),
    ));
    await tester.pumpAndSettle();
  }

  final save = find.widgetWithIcon(IconButton, Icons.check);

  testWidgets('disables saving for empty and whitespace-only names',
      (tester) async {
    await pumpEditor(tester);
    final name = find.byType(TextField).first;

    expect(tester.widget<IconButton>(save).onPressed, isNull);
    await tester.enterText(name, '   ');
    await tester.pump();
    expect(tester.widget<IconButton>(save).onPressed, isNull);
    await tester.enterText(name, 'A template');
    await tester.pump();
    expect(tester.widget<IconButton>(save).onPressed, isNotNull);
  });

  testWidgets('saves a template with a trimmed name', (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, '  A template ');
    await tester.pump();
    await tester.runAsync(() async {
      tester.widget<IconButton>(save).onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    final templates = await tester.runAsync(TemplateDao.getAll);
    expect(templates!.single.name, 'A template');
  });
}
