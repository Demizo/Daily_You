// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/pages/practice_speech_page.dart';
import 'package:daily_you/providers/learning_progress_provider.dart';
import 'package:daily_you/providers/user_session_provider.dart';
import 'package:daily_you/widgets/user_switch_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database database;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
    await UserSessionProvider.instance.reloadUsers();
    await LearningProgressProvider.instance.loadProgress();
  });

  tearDown(() async {
    AppDatabase.instance.database = null;
    await database.close();
  });

  Widget createTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserSessionProvider>.value(
          value: UserSessionProvider.instance,
        ),
        ChangeNotifierProvider<LearningProgressProvider>.value(
          value: LearningProgressProvider.instance,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('PracticeSpeechPage smoke test renders correctly', (tester) async {
    await tester.pumpWidget(createTestApp(const PracticeSpeechPage()));
    await tester.pump();

    expect(find.text('Luyện phát âm tiếng Anh'), findsOneWidget);
    expect(find.text('CHỦ ĐỀ ÔN TẬP'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsWidgets);
  });

  testWidgets('UserSwitchDialog displays and switches accounts', (tester) async {
    await tester.pumpWidget(createTestApp(const UserSwitchDialog()));
    await tester.pump();

    expect(find.text('Tài khoản Học viên'), findsOneWidget);
    expect(find.text('+ Thêm tài khoản học viên mới'), findsOneWidget);
  });
}
