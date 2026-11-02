// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/study_sentence.dart';
import 'package:sqflite/sqflite.dart';

class StudySentenceDao {
  /// Lấy toàn bộ câu: gồm câu hệ thống (userId IS NULL) và câu của học viên chỉ định.
  static Future<List<StudySentence>> getAll({
    int? userId,
    DatabaseExecutor? executor,
  }) async {
    final db = AppDatabase.executorOr(executor);
    String whereClause;
    List<dynamic> whereArgs;

    if (userId != null) {
      whereClause =
          '${StudySentenceFields.userId} IS NULL OR ${StudySentenceFields.userId} = ?';
      whereArgs = [userId];
    } else {
      whereClause = '${StudySentenceFields.userId} IS NULL';
      whereArgs = [];
    }

    final maps = await db.query(
      studySentencesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${StudySentenceFields.id} ASC',
    );
    return maps.map((json) => StudySentence.fromJson(json)).toList();
  }

  /// Lọc câu theo chủ đề ('all', 'daily', 'travel', 'work', 'dining', 'custom').
  static Future<List<StudySentence>> getByTopic(
    String topic, {
    int? userId,
    DatabaseExecutor? executor,
  }) async {
    final db = AppDatabase.executorOr(executor);

    if (topic == 'all') {
      return getAll(userId: userId, executor: executor);
    }

    if (topic == 'custom') {
      if (userId == null) return [];
      final maps = await db.query(
        studySentencesTable,
        where: '${StudySentenceFields.userId} = ?',
        whereArgs: [userId],
        orderBy: '${StudySentenceFields.id} DESC',
      );
      return maps.map((json) => StudySentence.fromJson(json)).toList();
    }

    String whereClause;
    List<dynamic> whereArgs;

    if (userId != null) {
      whereClause =
          '${StudySentenceFields.topic} = ? AND (${StudySentenceFields.userId} IS NULL OR ${StudySentenceFields.userId} = ?)';
      whereArgs = [topic, userId];
    } else {
      whereClause =
          '${StudySentenceFields.topic} = ? AND ${StudySentenceFields.userId} IS NULL';
      whereArgs = [topic];
    }

    final maps = await db.query(
      studySentencesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${StudySentenceFields.id} ASC',
    );
    return maps.map((json) => StudySentence.fromJson(json)).toList();
  }

  /// Thêm câu luyện tập mới (cho cả hệ thống lẫn người dùng tự tạo).
  static Future<StudySentence> add(
    StudySentence sentence, {
    DatabaseExecutor? executor,
  }) async {
    final db = AppDatabase.executorOr(executor);
    final id = await db.insert(studySentencesTable, sentence.toJson());
    return sentence.copy(id: id);
  }

  /// Xóa câu tự tạo.
  static Future<void> remove(int id, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      studySentencesTable,
      where: '${StudySentenceFields.id} = ?',
      whereArgs: [id],
    );
  }

  /// Khởi tạo sẵn ~24 câu mẫu thực tế thuộc 4 chủ đề giao tiếp thông dụng.
  static Future<void> seedDefaultSentences(DatabaseExecutor db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $studySentencesTable WHERE ${StudySentenceFields.userId} IS NULL'),
    );
    if ((count ?? 0) > 0) return;

    final now = DateTime.now();

    final defaultSentences = [
      // 1. Giao tiếp hằng ngày (Daily)
      StudySentence(
        topic: 'daily',
        sentence: 'Practice makes perfect.',
        meaning: 'Có công mài sắt, có ngày nên kim.',
        ipa: '/ˈpræk.tɪs meɪks ˈpɜː.fɪkt/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'daily',
        sentence: 'I love learning English every day.',
        meaning: 'Tôi yêu việc học tiếng Anh mỗi ngày.',
        ipa: '/aɪ lʌv ˈlɜː.nɪŋ ˈɪŋ.ɡlɪʃ ˈev.ri deɪ/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'daily',
        sentence: 'Good morning, how are you today?',
        meaning: 'Chào buổi sáng, hôm nay bạn thế nào?',
        ipa: '/ɡʊd ˈmɔː.nɪŋ haʊ ɑː juː təˈdeɪ/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'daily',
        sentence: 'Consistency is the key to mastering English.',
        meaning: 'Sự kiên trì là chìa khóa để làm chủ tiếng Anh.',
        ipa: '/kənˈsɪs.tən.si ɪz ðə kiː tuː ˈmɑː.stə.rɪŋ ˈɪŋ.ɡlɪʃ/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'daily',
        sentence: 'Could you please speak a little slower?',
        meaning: 'Bạn có thể nói chậm lại một chút được không?',
        ipa: '/kʊd juː pliːz spiːk ə ˈlɪt.əl ˈsləʊ.ər/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'daily',
        sentence: 'It was a pleasure meeting you today.',
        meaning: 'Rất vui được gặp bạn ngày hôm nay.',
        ipa: '/ɪt wɒz ə ˈpleʒ.ər ˈmiː.tɪŋ juː təˈdeɪ/',
        timeCreate: now,
      ),

      // 2. Du lịch & Sân bay (Travel)
      StudySentence(
        topic: 'travel',
        sentence: 'Where is the nearest subway station?',
        meaning: 'Ga tàu điện ngầm gần nhất ở đâu?',
        ipa: '/weər ɪz ðə ˈnɪə.rɪst ˈsʌb.weɪ ˈsteɪ.ʃən/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'travel',
        sentence: 'I would like to check in for my flight.',
        meaning: 'Tôi muốn làm thủ tục cho chuyến bay của mình.',
        ipa: '/aɪ wʊd laɪk tuː tʃek ɪn fɔː maɪ flaɪt/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'travel',
        sentence: 'Could you show me the way to the airport?',
        meaning: 'Bạn có thể chỉ đường cho tôi đến sân bay không?',
        ipa: '/kʊd juː ʃəʊ miː ðə weɪ tuː ði ˈeə.pɔːt/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'travel',
        sentence: 'How much is a round-trip ticket to London?',
        meaning: 'Giá vé khứ hồi đi London là bao nhiêu?',
        ipa: '/haʊ mʌtʃ ɪz ə raʊnd trɪp ˈtɪk.ɪt tuː ˈlʌn.dən/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'travel',
        sentence: 'Can I have a window seat, please?',
        meaning: 'Cho tôi xin một chỗ ngồi gần cửa sổ được không?',
        ipa: '/kæn aɪ hæv ə ˈwɪn.dəʊ siːt pliːz/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'travel',
        sentence: 'Is there a pharmacy around here?',
        meaning: 'Gần đây có tiệm thuốc nào không?',
        ipa: '/ɪz ðeər ə ˈfɑː.mə.si əˈraʊnd hɪər/',
        timeCreate: now,
      ),

      // 3. Công sở & Phỏng vấn (Work)
      StudySentence(
        topic: 'work',
        sentence: "Let's schedule a meeting for tomorrow morning.",
        meaning: 'Hãy lên lịch cuộc họp vào sáng mai nhé.',
        ipa: '/lets ˈʃedʒ.uːl ə ˈmiː.tɪŋ fɔː təˈmɒr.əʊ ˈmɔː.nɪŋ/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'work',
        sentence: 'I am excited about this new project.',
        meaning: 'Tôi rất hào hứng với dự án mới này.',
        ipa: '/aɪ æm ɪkˈsaɪ.tɪd əˈbaʊt ðɪs njuː ˈprɒdʒ.ekt/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'work',
        sentence: 'Could you send me the latest sales report?',
        meaning: 'Bạn có thể gửi cho tôi báo cáo doanh số mới nhất không?',
        ipa: '/kʊd juː send miː ðə ˈleɪ.tɪst seɪlz rɪˈpɔːt/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'work',
        sentence: 'My greatest strength is problem-solving.',
        meaning: 'Thế mạnh lớn nhất của tôi là giải quyết vấn đề.',
        ipa: '/maɪ ˈɡreɪ.tɪst streŋθ ɪz ˈprɒb.ləm ˈsɒl.vɪŋ/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'work',
        sentence: 'Thank you for your valuable feedback.',
        meaning: 'Cảm ơn vì những góp ý quý báu của bạn.',
        ipa: '/θæŋk juː fɔː jɔː ˈvæl.jʊ.ə.bəl ˈfiːd.bæk/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'work',
        sentence: 'We need to meet the deadline next Friday.',
        meaning: 'Chúng ta cần hoàn thành trước hạn chót thứ Sáu tới.',
        ipa: '/wiː niːd tuː miːt ðə ˈded.laɪn nekst ˈfraɪ.deɪ/',
        timeCreate: now,
      ),

      // 4. Nhà hàng & Ẩm thực (Dining)
      StudySentence(
        topic: 'dining',
        sentence: 'May I see the menu, please?',
        meaning: 'Tôi có thể xem thực đơn được không?',
        ipa: '/meɪ aɪ siː ðə ˈmen.juː pliːz/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'dining',
        sentence: 'I would like to order a cup of cappuccino.',
        meaning: 'Tôi muốn gọi một tách cappuccino.',
        ipa: '/aɪ wʊd laɪk tuː ˈɔː.dər ə kʌp əv ˌkæp.əˈtʃiː.nəʊ/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'dining',
        sentence: 'Can I pay by credit card?',
        meaning: 'Tôi có thể thanh toán bằng thẻ tín dụng không?',
        ipa: '/kæn aɪ peɪ baɪ ˈkred.ɪt kɑːd/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'dining',
        sentence: 'Could we have the bill, please?',
        meaning: 'Cho chúng tôi xin hóa đơn thanh toán nhé.',
        ipa: '/kʊd wiː hæv ðə bɪl pliːz/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'dining',
        sentence: 'Does this dish contain any peanuts?',
        meaning: 'Món này có chứa đậu phộng không?',
        ipa: '/dʌz ðɪs dɪʃ kənˈteɪn ˈen.i ˈpiː.nʌts/',
        timeCreate: now,
      ),
      StudySentence(
        topic: 'dining',
        sentence: 'This steak is absolutely delicious.',
        meaning: 'Món bít tết này thực sự rất ngon.',
        ipa: '/ðɪs steɪk ɪz ˌæb.səˈluːt.li dɪˈlɪʃ.əs/ ',
        timeCreate: now,
      ),
    ];

    final batch = db.batch();
    for (final s in defaultSentences) {
      batch.insert(studySentencesTable, s.toJson());
    }
    await batch.commit(noResult: true);
  }
}

