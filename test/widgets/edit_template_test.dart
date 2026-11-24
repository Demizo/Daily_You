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

  testWidgets('rejects empty and whitespace-only template names',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EditTemplate(),
    ));
    await tester.pumpAndSettle();

    final name = find.byType(TextField).first;
    final save = find.widgetWithIcon(IconButton, Icons.check);
    for (final value in ['', '   ']) {
      await tester.enterText(name, value);
      await tester.tap(save);
      await tester.pump();

      expect(find.text('Enter a template name'), findsOneWidget);
      expect(find.byType(EditTemplate), findsOneWidget);
    }

    expect(await tester.runAsync(TemplateDao.getAll), isEmpty);
  });

  testWidgets('successfully creates a template with a non-empty name',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EditTemplate(),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'A template');
    await tester.pump();
    expect(find.text('Enter a template name'), findsNothing);
    await tester.runAsync(() async {
      final save = tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.check));
      await Function.apply(save.onPressed!, []);
    });
    await tester.pumpAndSettle();
    final templates = await tester.runAsync(TemplateDao.getAll);
    expect(templates, hasLength(1));
    expect(templates!.single.name, 'A template');
  });
}
