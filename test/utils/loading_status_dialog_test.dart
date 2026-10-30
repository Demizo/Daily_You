// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late LoadingStatusDialog loadingStatus;

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        loadingStatus = LoadingStatusDialog(context);
        return const Scaffold();
      }),
    ));
  }

  testWidgets('shows the latest status until disposed', (tester) async {
    await pumpHost(tester);

    loadingStatus.show();
    loadingStatus.update('Restoring 40%');
    await pumpFrames(tester);
    expect(find.text('Restoring 40%'), findsOneWidget);

    loadingStatus.dispose();
    await pumpFrames(tester);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('hides while a task runs and shows again afterwards',
      (tester) async {
    await pumpHost(tester);
    loadingStatus.show();
    await pumpFrames(tester);

    var dialogsDuringTask = -1;
    await loadingStatus.whileHidden(() async {
      await pumpFrames(tester);
      dialogsDuringTask = find.byType(Dialog).evaluate().length;
    });
    await pumpFrames(tester);

    expect(dialogsDuringTask, 0);
    expect(find.byType(Dialog), findsOneWidget);

    loadingStatus.dispose();
  });

  testWidgets('stays hidden after a task when it was not showing',
      (tester) async {
    await pumpHost(tester);

    await loadingStatus.whileHidden(() async {});
    await pumpFrames(tester);

    expect(find.byType(Dialog), findsNothing);

    loadingStatus.dispose();
  });
}
