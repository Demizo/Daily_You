// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/settings_rows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  Future<void> pumpRow(WidgetTester tester, Widget row) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: row)));
  }

  testWidgets('selecting the current option reports it again', (tester) async {
    final selected = <String>[];
    await pumpRow(
      tester,
      SettingsChoiceRow<String>(
        title: 'Tag',
        value: 'label',
        options: const {'none': 'None', 'label': 'Favorite'},
        onChanged: selected.add,
      ),
    );

    await tester.tap(find.text('Tag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorite').last);
    await tester.pumpAndSettle();

    expect(selected, ['label']);
  });

  testWidgets('an option accessory sits beside its label in the choice dialog',
      (tester) async {
    await pumpRow(
      tester,
      SettingsChoiceRow<String>(
        title: 'Tag',
        value: 'label',
        options: const {'none': 'None', 'label': 'Label'},
        accessoryBuilder: (option) =>
            option == 'label' ? const Text('Favorite') : null,
        onChanged: (_) {},
      ),
    );

    await tester.tap(find.text('Tag'));
    await tester.pumpAndSettle();

    expect(find.text('Label'), findsNWidgets(2));
    expect(find.text('Favorite'), findsNWidgets(2));
  });

  testWidgets('a split toggle row shows its divider only while on',
      (tester) async {
    Widget row(bool value) => SettingsToggleRow(
          title: 'Backups',
          value: value,
          onChanged: (_) {},
          onOpenOptions: () {},
        );

    await pumpRow(tester, row(false));
    expect(find.byType(VerticalDivider), findsNothing);

    await pumpRow(tester, row(true));
    expect(find.byType(VerticalDivider), findsOneWidget);
  });
}
