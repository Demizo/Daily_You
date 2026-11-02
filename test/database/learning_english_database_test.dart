// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/practice_history_dao.dart';
import 'package:daily_you/database/pronunciation_result_dao.dart';
import 'package:daily_you/database/user_dao.dart';
import 'package:daily_you/models/practice_history.dart';
import 'package:daily_you/models/pronunciation_result.dart';
import 'package:daily_you/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database database;
  final now = DateTime(2026, 11, 2, 10, 0, 0);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
  });

  tearDown(() async {
    AppDatabase.instance.database = null;
    await database.close();
  });

  group('UserDao Tests', () {
    test('Create, Read, Update, Delete user', () async {
      // 1. Thêm user
      final user = await UserDao.add(User(
        authId: 'firebase_uid_123',
        name: 'Nguyen Van A',
        email: 'vana@example.com',
        timeCreate: now,
        timeModified: now,
      ));

      expect(user.id, isNotNull);
      expect(user.name, 'Nguyen Van A');
      expect(user.authId, 'firebase_uid_123');
      expect(user.email, 'vana@example.com');

      // 2. Tìm theo ID
      final byId = await UserDao.get(user.id!);
      expect(byId, isNotNull);
      expect(byId!.name, 'Nguyen Van A');

      // 3. Tìm theo AuthId (hỗ trợ Firebase/Supabase Auth)
      final byAuthId = await UserDao.getByAuthId('firebase_uid_123');
      expect(byAuthId, isNotNull);
      expect(byAuthId!.id, user.id);

      // 4. Tìm theo Email
      final byEmail = await UserDao.getByEmail('vana@example.com');
      expect(byEmail, isNotNull);
      expect(byEmail!.id, user.id);

      // 5. Cập nhật thông tin user (không có trường password)
      final updated = user.copy(
        name: 'Nguyen Van A Updated',
        timeModified: DateTime(2026, 11, 2, 11, 0, 0),
      );
      await UserDao.update(updated);

      final reloaded = await UserDao.get(user.id!);
      expect(reloaded!.name, 'Nguyen Van A Updated');

      // 6. Xóa user
      await UserDao.remove(user.id!);
      final deleted = await UserDao.get(user.id!);
      expect(deleted, isNull);
    });
  });

  group('PracticeHistoryDao Tests', () {
    test('ActivityType parsing and extensibility fallback', () {
      expect(ActivityType.fromValue('PRONUNCIATION'), ActivityType.pronunciation);
      expect(ActivityType.fromValue('LISTENING'), ActivityType.listening);
      expect(ActivityType.fromValue('VOCABULARY'), ActivityType.vocabulary);
      expect(ActivityType.fromValue('SPEAKING'), ActivityType.speaking);
      expect(ActivityType.fromValue('READING'), ActivityType.reading);
      expect(ActivityType.fromValue('OTHER'), ActivityType.other);

      // Mở rộng tương lai: giá trị mới không làm crash app, fallback an toàn sang OTHER
      expect(ActivityType.fromValue('WRITING_AI'), ActivityType.other);
      expect(ActivityType.fromValue('GRAMMAR_CHALLENGE'), ActivityType.other);
      expect(ActivityType.fromValue(null), ActivityType.other);
      expect(ActivityType.fromValue(''), ActivityType.other);
    });

    test('Practice session lifecycle and filtering by user/date/status', () async {
      final user1 = await UserDao.add(User(
        name: 'User One',
        timeCreate: now,
        timeModified: now,
      ));
      final user2 = await UserDao.add(User(
        name: 'User Two',
        timeCreate: now,
        timeModified: now,
      ));

      // 1. Tạo session cho user 1
      final practice1 = await PracticeHistoryDao.add(PracticeHistory(
        userId: user1.id!,
        activityType: ActivityType.pronunciation,
        content: 'How is the weather today?',
        startedAt: now,
        practiceDate: '2026-11-02',
        status: PracticeStatus.inProgress,
        timeCreate: now,
        timeModified: now,
      ));

      // 2. Tạo session cho user 2 cùng ngày (kiểm tra phân tách dữ liệu)
      final practiceUser2 = await PracticeHistoryDao.add(PracticeHistory(
        userId: user2.id!,
        activityType: ActivityType.listening,
        content: 'Audio conversation 1',
        startedAt: now,
        practiceDate: '2026-11-02',
        status: PracticeStatus.completed,
        endedAt: now.add(const Duration(minutes: 5)),
        durationSeconds: 300,
        timeCreate: now,
        timeModified: now,
      ));

      // 3. Phân tách người dùng: user1 chỉ thấy bài của mình
      final user1List = await PracticeHistoryDao.getByUserId(user1.id!);
      expect(user1List.length, 1);
      expect(user1List.first.id, practice1.id);
      expect(user1List.first.content, 'How is the weather today?');

      final user2List = await PracticeHistoryDao.getByUserId(user2.id!);
      expect(user2List.length, 1);
      expect(user2List.first.id, practiceUser2.id);

      // 4. Lọc theo ngày
      final todayList = await PracticeHistoryDao.getByUserAndDate(user1.id!, '2026-11-02');
      expect(todayList.length, 1);

      final otherDayList = await PracticeHistoryDao.getByUserAndDate(user1.id!, '2026-11-01');
      expect(otherDayList, isEmpty);

      // 5. Cập nhật hoàn thành session
      final completedPractice = practice1.copy(
        status: PracticeStatus.completed,
        endedAt: now.add(const Duration(minutes: 2)),
        durationSeconds: 120,
        timeModified: DateTime(2026, 11, 2, 10, 2, 0),
      );
      await PracticeHistoryDao.update(completedPractice);

      final reloadedPractice = await PracticeHistoryDao.get(practice1.id!);
      expect(reloadedPractice!.status, PracticeStatus.completed);
      expect(reloadedPractice.durationSeconds, 120);

      // 6. Lọc theo trạng thái
      final completedList = await PracticeHistoryDao.getByUserAndStatus(
        user1.id!,
        PracticeStatus.completed,
      );
      expect(completedList.length, 1);

      final inProgressList = await PracticeHistoryDao.getByUserAndStatus(
        user1.id!,
        PracticeStatus.inProgress,
      );
      expect(inProgressList, isEmpty);
    });
  });

  group('PronunciationResultDao Tests', () {
    test('Handles full result with word scores and mispronounced words', () async {
      final user = await UserDao.add(User(
        name: 'Hoc Vien',
        timeCreate: now,
        timeModified: now,
      ));

      final practice = await PracticeHistoryDao.add(PracticeHistory(
        userId: user.id!,
        activityType: ActivityType.pronunciation,
        content: 'She sells seashells by the seashore.',
        startedAt: now,
        practiceDate: '2026-11-02',
        status: PracticeStatus.completed,
        timeCreate: now,
        timeModified: now,
      ));

      final result = await PronunciationResultDao.add(PronunciationResult(
        userId: user.id!,
        practiceId: practice.id!,
        referenceSentence: 'She sells seashells by the seashore.',
        recognizedText: 'She sells sea shells by the sea shore.',
        overallScore: 88.5,
        wordScores: [
          const WordScore(word: 'She', score: 95.0),
          const WordScore(word: 'sells', score: 90.0),
          const WordScore(word: 'seashells', score: 75.5),
        ],
        mispronouncedWords: [
          const MispronouncedWord(
            word: 'seashells',
            expectedPhoneme: 'ˈsiːʃelz',
            actualPhoneme: 'ˈsiːselz',
            errorType: 'consonant_substitution',
          ),
        ],
        feedback: 'Phát âm tốt, cần chú ý âm /ʃ/ trong từ seashells.',
        suggestions: 'Luyện tập đặt đầu lưỡi hơi cong về sau khi phát âm /ʃ/.',
        evaluatedAt: now,
        audioFilePath: '/storage/emulated/0/DailyYou/audio/test_01.m4a',
        timeCreate: now,
      ));

      expect(result.id, isNotNull);

      // Đọc lại từ database
      final reloaded = await PronunciationResultDao.get(result.id!);
      expect(reloaded, isNotNull);
      expect(reloaded!.referenceSentence, 'She sells seashells by the seashore.');
      expect(reloaded.recognizedText, 'She sells sea shells by the sea shore.');
      expect(reloaded.overallScore, 88.5);
      expect(reloaded.wordScores?.length, 3);
      expect(reloaded.wordScores?[0].word, 'She');
      expect(reloaded.wordScores?[0].score, 95.0);
      expect(reloaded.mispronouncedWords?.length, 1);
      expect(reloaded.mispronouncedWords?[0].word, 'seashells');
      expect(reloaded.mispronouncedWords?[0].actualPhoneme, 'ˈsiːselz');
      expect(reloaded.audioFilePath, '/storage/emulated/0/DailyYou/audio/test_01.m4a');
    });

    test('Supports API scenarios where scores or mispronounced words are null or empty', () async {
      final user = await UserDao.add(User(
        name: 'Hoc Vien 2',
        timeCreate: now,
        timeModified: now,
      ));

      final practice = await PracticeHistoryDao.add(PracticeHistory(
        userId: user.id!,
        activityType: ActivityType.pronunciation,
        content: 'Good morning everyone.',
        startedAt: now,
        practiceDate: '2026-11-02',
        status: PracticeStatus.completed,
        timeCreate: now,
        timeModified: now,
      ));

      // Giả lập API chỉ trả recognizedText mà KHÔNG tính điểm, KHÔNG phân tích từ sai
      final rawApiResult = await PronunciationResultDao.add(PronunciationResult(
        userId: user.id!,
        practiceId: practice.id!,
        referenceSentence: 'Good morning everyone.',
        recognizedText: 'Good morning everyone',
        overallScore: null, // API không cung cấp
        wordScores: null, // API không cung cấp
        mispronouncedWords: null, // API không cung cấp
        feedback: null,
        suggestions: null,
        evaluatedAt: now,
        audioFilePath: null,
        timeCreate: now,
      ));

      final fetched = await PronunciationResultDao.get(rawApiResult.id!);
      expect(fetched, isNotNull);
      expect(fetched!.overallScore, isNull);
      expect(fetched.wordScores, isNull);
      expect(fetched.mispronouncedWords, isNull);
      expect(fetched.recognizedText, 'Good morning everyone');
    });

    test('Query results by practiceId and userId isolation', () async {
      final userA = await UserDao.add(User(name: 'User A', timeCreate: now, timeModified: now));
      final userB = await UserDao.add(User(name: 'User B', timeCreate: now, timeModified: now));

      final practiceA = await PracticeHistoryDao.add(PracticeHistory(
        userId: userA.id!,
        activityType: ActivityType.pronunciation,
        content: 'Sentence A',
        startedAt: now,
        practiceDate: '2026-11-02',
        status: PracticeStatus.completed,
        timeCreate: now,
        timeModified: now,
      ));

      final practiceB = await PracticeHistoryDao.add(PracticeHistory(
        userId: userB.id!,
        activityType: ActivityType.pronunciation,
        content: 'Sentence B',
        startedAt: now,
        practiceDate: '2026-11-02',
        status: PracticeStatus.completed,
        timeCreate: now,
        timeModified: now,
      ));

      await PronunciationResultDao.add(PronunciationResult(
        userId: userA.id!,
        practiceId: practiceA.id!,
        referenceSentence: 'Sentence A',
        overallScore: 90.0,
        evaluatedAt: now,
        timeCreate: now,
      ));

      await PronunciationResultDao.add(PronunciationResult(
        userId: userB.id!,
        practiceId: practiceB.id!,
        referenceSentence: 'Sentence B',
        overallScore: 70.0,
        evaluatedAt: now,
        timeCreate: now,
      ));

      // Kiểm tra lấy theo practiceId
      final resultsA = await PronunciationResultDao.getByPracticeId(practiceA.id!);
      expect(resultsA.length, 1);
      expect(resultsA.first.referenceSentence, 'Sentence A');

      // Kiểm tra phân tách dữ liệu theo userId
      final userAResults = await PronunciationResultDao.getByUserId(userA.id!);
      expect(userAResults.length, 1);
      expect(userAResults.first.overallScore, 90.0);

      final userBResults = await PronunciationResultDao.getByUserId(userB.id!);
      expect(userBResults.length, 1);
      expect(userBResults.first.overallScore, 70.0);
    });
  });

  group('Database Migration v6 -> v7 Test', () {
    test('onUpgrade successfully creates new tables and indexes', () async {
      // Mở DB mới trống không qua createSchema
      final testDb = await databaseFactory.openDatabase(inMemoryDatabasePath);
      // Giả lập oldVersion = 6
      await AppDatabase.instance.onUpgrade(testDb, 6, 7);

      // Kiểm tra sự tồn tại của 3 bảng mới
      final tables = await testDb.query(
        'sqlite_master',
        where: "type = 'table' AND name IN (?, ?, ?)",
        whereArgs: [usersTable, practiceHistoryTable, pronunciationResultsTable],
      );
      expect(tables.length, 3);

      await testDb.close();
    });
  });
}

