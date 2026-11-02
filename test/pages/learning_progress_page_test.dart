// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/learning_progress.dart';
import 'package:daily_you/pages/learning_progress_page.dart';
import 'package:daily_you/providers/learning_progress_provider.dart';
import 'package:daily_you/providers/user_session_provider.dart';
import 'package:daily_you/widgets/weekly_progress_chart.dart';
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

  Widget createTestWidget(Widget child,
      {Size size = const Size(390, 844)}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LearningProgressProvider>.value(
          value: LearningProgressProvider.instance,
        ),
        ChangeNotifierProvider<UserSessionProvider>.value(
          value: UserSessionProvider.instance,
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    );
  }

  group('WeeklyProgressChart Widget Tests', () {
    testWidgets('Renders 7 daily bars and summary', (tester) async {
      final now = DateTime(2026, 11, 2);
      final days = List.generate(7, (i) {
        final dt = now.subtract(Duration(days: 6 - i));
        return DayProgressItem(
          date: dt,
          dateString: dt.toIso8601String().substring(0, 10),
          dayOfWeekLabel: 'T${i + 2}',
          studySeconds: (i + 1) * 300, // 5, 10, 15... phút
          completedSessionsCount: 1,
          isGoalAchieved: i >= 3,
        );
      });

      final weeklyData = WeeklyProgressData(
        days: days,
        totalWeekMinutes: 140,
        averageDailyMinutes: 20.0,
        bestDay: days.last,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WeeklyProgressChart(
            weeklyData: weeklyData,
            dailyGoalMinutes: 20,
          ),
        ),
      ));

      expect(find.text('Tổng tuần: 140 phút'), findsOneWidget);
      expect(find.text('TB: 20.0 phút/ngày'), findsOneWidget);
      expect(find.text('T2'), findsWidgets);
    });
  });

  group('LearningProgressPage Widget Tests', () {
    testWidgets('Renders empty state when user has no practice records',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const LearningProgressPage()));
      // Allow postFrameCallback to fire and loadProgress to finish
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Tiến độ học tập'), findsOneWidget);
      expect(find.text('Bắt đầu hành trình phát âm AI!'), findsOneWidget);
      expect(find.text('Bắt đầu bài học đầu tiên'), findsOneWidget);
    });

    testWidgets('Responsive rendering on tablet / large screen (768x1024)',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LearningProgressPage(),
        size: const Size(768, 1024),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Tiến độ học tập'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
