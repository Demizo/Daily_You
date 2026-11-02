// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/widgets/image_decoded_notification.dart';
import 'package:daily_you/widgets/snapshot_while_scrolling.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Announcer extends StatelessWidget {
  const _Announcer();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => const ImageDecodedNotification().dispatch(context),
      child: const SizedBox.square(dimension: 40),
    );
  }
}

void main() {
  late ValueNotifier<bool> scrolling;

  setUp(() => scrolling = ValueNotifier<bool>(false));
  tearDown(() => scrolling.dispose());

  Future<SnapshotController> pumpRow(WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SnapshotWhileScrolling(
        scrolling: scrolling,
        child: const _Announcer(),
      ),
    ));
    return tester
        .widget<SnapshotWidget>(find.byType(SnapshotWidget))
        .controller;
  }

  testWidgets('allows snapshots only while scrolling', (tester) async {
    final controller = await pumpRow(tester);
    expect(controller.allowSnapshotting, isFalse);

    scrolling.value = true;
    expect(controller.allowSnapshotting, isTrue);

    scrolling.value = false;
    expect(controller.allowSnapshotting, isFalse);
  });

  testWidgets('takes a fresh snapshot when an image decodes mid scroll',
      (tester) async {
    final controller = await pumpRow(tester);
    scrolling.value = true;
    var changes = 0;
    controller.addListener(() => changes++);

    await tester.tap(find.byType(_Announcer));

    expect(changes, 2);
    expect(controller.allowSnapshotting, isTrue);
  });

  testWidgets('leaves rows alone when an image decodes at rest',
      (tester) async {
    final controller = await pumpRow(tester);
    var changes = 0;
    controller.addListener(() => changes++);

    await tester.tap(find.byType(_Announcer));

    expect(changes, 0);
    expect(controller.allowSnapshotting, isFalse);
  });

  testWidgets('notifyWhenDecoded announces a decoded image', (tester) async {
    final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    var announced = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: NotificationListener<ImageDecodedNotification>(
        onNotification: (_) {
          announced++;
          return true;
        },
        child: Image.memory(bytes, frameBuilder: notifyWhenDecoded),
      ),
    ));
    expect(announced, 0);

    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    await tester.pump();

    expect(announced, 1);
  });
}
