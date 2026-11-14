// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/providers/gallery_selection.dart';
import 'package:daily_you/widgets/selectable_entry_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';
import '../support/gallery_page_harness.dart';

void main() {
  useTemporaryConfig();

  final selection = GallerySelection.instance;

  tearDown(resetGalleryPageState);

  testWidgets('long pressing a log starts selecting it', (tester) async {
    await pumpGalleryPage(tester);

    await tester.longPress(find.byType(SelectableEntryCard).first);
    await tester.pump();

    expect(selection.active, isTrue);
    expect(selection.selectedEntries.single.id, 1);
    expect(selection.selectedCount, 1);
  });

  testWidgets('tapping logs toggles them and the last one ends selecting',
      (tester) async {
    await pumpGalleryPage(tester);

    await tester.longPress(find.byType(SelectableEntryCard).first);
    await tester.pump();
    await tester.tap(find.byType(SelectableEntryCard).last);
    await tester.pump();
    expect(selection.selectedCount, 2);

    await tester.tap(find.byType(SelectableEntryCard).first);
    await tester.tap(find.byType(SelectableEntryCard).last);
    await tester.pump();
    expect(selection.active, isFalse);
  });

  testWidgets('holding and dragging selects the logs it passes over',
      (tester) async {
    await pumpGalleryPage(tester);

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(SelectableEntryCard).first));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture
        .moveTo(tester.getCenter(find.byType(SelectableEntryCard).last));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(selection.selectedCount, 2);
  });
}
