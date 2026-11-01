import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vietnamese Localization Tests', () {
    test('AppLocalizations supports vi locale', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('vi')), isTrue);
    });

    test('Vietnamese translations load correctly', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));

      // Check app title & navigation
      expect(l10n.appTitle, 'Daily You');
      expect(l10n.pageStatisticsTitle, 'Thống kê');
      expect(l10n.pageCalendarTitle, 'Lịch');
      expect(l10n.pageSettingsTitle, 'Cài đặt');

      // Check default tags and categories
      expect(l10n.tagCategoryEmotionsName, 'Cảm xúc');
      expect(l10n.tagCategoryActivitiesName, 'Hoạt động');
      expect(l10n.tagFavoriteName, 'Yêu thích');
      expect(l10n.tagEnergyName, 'Năng lượng');
      expect(l10n.tagExcitedName, 'Hào hứng');
      expect(l10n.tagGratefulName, 'Biết ơn');
      expect(l10n.tagCalmName, 'Bình yên');
      expect(l10n.tagTiredName, 'Mệt mỏi');
      expect(l10n.tagAnxiousName, 'Lo lắng');
      expect(l10n.tagAnnoyedName, 'Bực bội');
      expect(l10n.tagExerciseName, 'Tập thể dục');
      expect(l10n.tagSocializingName, 'Giao lưu');
      expect(l10n.tagHobbyName, 'Sở thích');
      expect(l10n.tagEntertainmentName, 'Giải trí');
      expect(l10n.tagDiningName, 'Ăn uống');
      expect(l10n.tagChoresName, 'Việc nhà');

      // Check default templates
      expect(l10n.templateDefaultTimestampTitle, 'Dấu thời gian');
      expect(l10n.templateDefaultSummaryTitle, 'Tóm tắt ngày');
      expect(l10n.templateDefaultReflectionTitle, 'Suy ngẫm');

      // Check chart titles
      expect(l10n.chartDistributionTitle('Yêu thích'), contains('Yêu thích'));
      expect(l10n.chartOverTimeTitle('Năng lượng'), contains('Năng lượng'));
    });
  });
}
