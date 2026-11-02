// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/widgets/icon_picker_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: IconPickerDialog(
            previewColor: Color(0xFF008080),
            initial: (type: TagIconType.materialIcon, value: null),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the dialog shell first, then icons a few frames later',
      (tester) async {
    await pumpDialog(tester);

    expect(find.byType(SearchBar), findsNothing);
    expect(find.byType(IconButton), findsNothing);

    await tester.pump();
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);

    await tester.pump();
    final firstChunk = tester.widgetList(find.byType(IconButton)).length;
    expect(firstChunk, inInclusiveRange(1, 14));

    await tester.pump();
    expect(tester.widgetList(find.byType(IconButton)).length,
        greaterThan(firstChunk));
  });

  testWidgets('ends with every visible group built', (tester) async {
    await pumpDialog(tester);
    await tester.pumpAndSettle();

    expect(find.byType(IconButton).evaluate().length, greaterThan(14));
    expect(find.text('No results'), findsNothing);
  });
}
