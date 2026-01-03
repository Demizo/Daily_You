// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => '今日を記録する！';

  @override
  String get dailyReminderDescription => '今日の記録を残しましょう…';

  @override
  String get pageHomeTitle => 'ホーム';

  @override
  String get flashbacksTitle => '回想';

  @override
  String get settingsFlashbacksExcludeBadDays => '気分が沈んだ日を除外';

  @override
  String get flaskbacksEmpty => 'まだ回想はありません…';

  @override
  String get flashbackGoodDay => 'よい一日';

  @override
  String get flashbackRandomDay => 'ある一日';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 週間前',
      one: '$count 週間前',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count か月前',
      one: '$count か月前',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年前',
      one: '$count 年前',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Gallery';

  @override
  String get searchLogsHint => '記録を検索…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の記録',
      one: '$count件の記録',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count文字',
      one: '$count文字',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'まだ記録はありません…';

  @override
  String get sortDateTitle => '日付';

  @override
  String get sortOrderAscendingTitle => '昇順';

  @override
  String get sortOrderDescendingTitle => '降順';

  @override
  String get pageStatisticsTitle => '統計';

  @override
  String get statisticsNotEnoughData => 'データが足りません…';

  @override
  String get statisticsRangeOneMonth => '一か月';

  @override
  String get statisticsRangeSixMonths => '六か月';

  @override
  String get statisticsRangeOneYear => '一年';

  @override
  String get statisticsRangeAllTime => 'すべての期間';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Summary';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag By Day';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Current Streak $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Longest Streak $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Days Since a Bad Day $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle => '外部ストレージにアクセスできません';

  @override
  String get errorExternalStorageAccessDescription =>
      'もしネットワークストレージを使用している場合は、サービスがオンラインであり、ネットワークに接続されていることを確認してください。\n\nそうでない場合、アプリは外部フォルダへのアクセス権を失っている可能性があります。設定に移動し、外部フォルダを再選択してアクセスを許可してください。\n\n注意：外部ストレージへのアクセスを復元するまで、変更内容は同期されません！';

  @override
  String get errorExternalStorageAccessContinue => 'ローカルデータベースを使用して続行';

  @override
  String get lastModified => '最終更新';

  @override
  String get writeSomethingHint => '何か書きましょう…';

  @override
  String get titleHint => 'タイトル…';

  @override
  String get deleteLogTitle => '記録を削除';

  @override
  String get deleteLogDescription => 'この記録を削除してもよろしいですか？';

  @override
  String get deletePhotoTitle => '写真を削除';

  @override
  String get deletePhotoDescription => 'この写真を削除してもよろしいですか？';

  @override
  String get pageSettingsTitle => '設定';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'First Day Of Week';

  @override
  String get settingsUseSystemAccentColor => 'Use System Accent Color';

  @override
  String get settingsCustomAccentColor => 'Custom Accent Color';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Show Flashbacks';

  @override
  String get settingsChangeMoodIcons => '気分のアイコンを変更する';

  @override
  String get moodIconPrompt => 'アイコンを入力してください';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get viewLayoutList => 'リスト';

  @override
  String get viewLayoutGrid => 'グリッド';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsDailyReminderOnboarding =>
      'Enable daily reminders to keep yourself consistent!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'The \'schedule alarms\' permission will be requested to send the reminder at a random moment or at your preferred time.';

  @override
  String get settingsDailyReminderTitle => 'Daily Reminder';

  @override
  String get settingsDailyReminderDescription => 'A gentle reminder each day';

  @override
  String get settingsReminderTime => 'Reminder Time';

  @override
  String get settingsFixedReminderTimeTitle => 'Fixed Reminder Time';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Pick a fixed time for the reminder';

  @override
  String get settingsAlwaysSendReminderTitle => 'Always Send Reminder';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Send reminder even if a log was already started';

  @override
  String get settingsCustomizeNotificationTitle => 'Customize Notifications';

  @override
  String get settingsTemplatesTitle => 'テンプレート';

  @override
  String get settingsDefaultTemplate => 'デフォルトテンプレート';

  @override
  String get manageTemplates => 'テンプレートを管理する';

  @override
  String get addTemplate => 'テンプレートを追加する';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'なし';

  @override
  String get noTemplatesDescription => 'テンプレートはまだ作成されていません…';

  @override
  String get settingsStorageTitle => 'ストレージ';

  @override
  String get settingsImageQuality => '画質';

  @override
  String get imageQualityHigh => '高';

  @override
  String get imageQualityMedium => '中';

  @override
  String get imageQualityLow => '低';

  @override
  String get imageQualityNoCompression => '圧縮なし';

  @override
  String get settingsLogFolder => '記録フォルダ';

  @override
  String get settingsImageFolder => '画像フォルダ';

  @override
  String get warningTitle => '警告';

  @override
  String get logFolderWarningDescription =>
      'If the selected folder already contains a \'daily_you.db\' file, it will be used to overwrite your existing logs!';

  @override
  String get errorTitle => 'エラー';

  @override
  String get logFolderErrorDescription => 'Failed to change log folder!';

  @override
  String get imageFolderErrorDescription => 'Failed to change image folder!';

  @override
  String get backupErrorDescription => 'Failed to create backup!';

  @override
  String get restoreErrorDescription => 'Failed to restore backup!';

  @override
  String get settingsBackupRestoreTitle => 'バックアップと復元';

  @override
  String get settingsBackup => 'バックアップ';

  @override
  String get settingsRestore => '復元';

  @override
  String get settingsRestorePromptDescription => 'これにより現在の設定が上書きされます！';

  @override
  String tranferStatus(Object percent) {
    return 'Transferring… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Creating Backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Restoring Backup… $percent%';
  }

  @override
  String get cleanUpStatus => 'Cleaning Up…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Export To Another Format';

  @override
  String get settingsExportFormatDescription =>
      'This should not be used as a backup!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Import From Another App';

  @override
  String get settingsTranslateCallToAction =>
      'Everyone should have access to a journal!';

  @override
  String get settingsHelpTranslate => '翻訳を手伝う';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Choose Format';

  @override
  String get logFormatDescription =>
      'Another app\'s format may not support all features. Please report any issues since third party formats may change at any time. This will not impact existing logs!';

  @override
  String get formatDailyYouJson => 'Daily You (JSON)';

  @override
  String get formatDaybook => 'Daybook';

  @override
  String get formatDaylio => 'Daylio';

  @override
  String get formatDiarium => 'Diarium';

  @override
  String get formatDiaro => 'Diaro';

  @override
  String get formatMyBrain => 'My Brain';

  @override
  String get formatOneShot => 'OneShot';

  @override
  String get formatPixels => 'Pixels';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => 'Delete All Logs';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Do you want to delete all of your logs?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Enter \'$prompt\' to confirm. This cannot be undone!';
  }

  @override
  String get settingsLanguageTitle => '言語';

  @override
  String get settingsAppLanguageTitle => 'アプリの言語';

  @override
  String get settingsOverrideAppLanguageTitle => 'アプリの言語を指定する';

  @override
  String get settingsSecurityTitle => 'セキュリティ';

  @override
  String get settingsSecurityRequirePassword => 'パスワードを使用する';

  @override
  String get settingsSecurityEnterPassword => 'パスワードを入力してください';

  @override
  String get settingsSecuritySetPassword => 'パスワードを設定する';

  @override
  String get settingsSecurityChangePassword => 'パスワードを変更する';

  @override
  String get settingsSecurityPassword => 'パスワード';

  @override
  String get settingsSecurityConfirmPassword => 'パスワードを確認する';

  @override
  String get settingsSecurityOldPassword => '現在のパスワード';

  @override
  String get settingsSecurityIncorrectPassword => 'パスワードが正しくありません';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get requiredPrompt => 'Required';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometric Unlock';

  @override
  String get unlockAppPrompt => 'Unlock the app';

  @override
  String get settingsAboutTitle => 'Daily Youについて';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsLicense => 'ライセンス';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'ソースコード';

  @override
  String get settingsMadeWithLove => '❤️ をこめて作りました';

  @override
  String get settingsConsiderSupporting => 'consider supporting';

  @override
  String get tagMoodTitle => '気分';
}
