// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/gallery_invite.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';
import '../support/gallery_page_harness.dart';

void main() {
  useTemporaryConfig();

  tearDown(resetGalleryPageState);

  testWidgets('invites writing a log while the gallery is mostly empty',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpGalleryPage(tester);

    expect(find.byType(GalleryInvite), findsOneWidget);
  });

  testWidgets('drops the invite once logs fill the screen', (tester) async {
    await pumpGalleryPage(tester, entryCount: 30);

    expect(find.byType(GalleryInvite), findsNothing);
  });
}
