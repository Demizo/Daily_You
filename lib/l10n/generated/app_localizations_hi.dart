// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'आज दर्ज करें!';

  @override
  String get dailyReminderDescription => 'अपना आज का दिन दर्ज करें…';

  @override
  String get pageHomeTitle => 'होम';

  @override
  String get flashbacksTitle => 'फ्लैशबैक्स';

  @override
  String get settingsFlashbacksExcludeBadDays => 'बुरे दिनों के अलावा';

  @override
  String get flaskbacksEmpty => 'अभी तक कोई फ़्लैशबैक नहीं…';

  @override
  String get flashbackGoodDay => 'अच्छा दिन';

  @override
  String get flashbackRandomDay => 'कोई भी दिन';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Weeks Ago',
      one: '$count Week Ago',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Months Ago',
      one: '$count Month Ago',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Years Ago',
      one: '$count Year Ago',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'गैलरी';

  @override
  String get searchLogsHint => 'लॉग्स खोजें…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '$count log',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '$count word',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'कोई लॉग नहीं…';

  @override
  String get sortDateTitle => 'दिनांक';

  @override
  String get sortOrderAscendingTitle => 'Ascending';

  @override
  String get sortOrderDescendingTitle => 'Descending';

  @override
  String get pageStatisticsTitle => 'आंकड़े';

  @override
  String get statisticsNotEnoughData => 'पर्याप्त डेटा नहीं है…';

  @override
  String get statisticsRangeOneMonth => '१ महीना';

  @override
  String get statisticsRangeSixMonths => '६ महीने';

  @override
  String get statisticsRangeOneYear => '१ वर्ष';

  @override
  String get statisticsRangeAllTime => 'सारा समय';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag सारांश';
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
  String get errorExternalStorageAccessTitle =>
      'Can\'t Access External Storage';

  @override
  String get errorExternalStorageAccessDescription =>
      'If you are using network storage make sure the service is online and you have network access.\n\nOtherwise, the app may have lost permissions for the external folder. Go to settings, and reselect the external folder to grant access.\n\nWarning, changes will not be synced until you restore access to the external storage location!';

  @override
  String get errorExternalStorageAccessContinue =>
      'लोकल डेटाबेस के साथ जारी रखें';

  @override
  String get lastModified => 'संशोधित';

  @override
  String get writeSomethingHint => 'कुछ लिखें…';

  @override
  String get titleHint => 'शीर्षक…';

  @override
  String get deleteLogTitle => 'लॉग हटाएं';

  @override
  String get deleteLogDescription => 'क्या आप इस लॉग को हटाना चाहते हैं?';

  @override
  String get deletePhotoTitle => 'फ़ोटो हटाएं';

  @override
  String get deletePhotoDescription => 'क्या आप इस फोटो को हटाना चाहते हैं?';

  @override
  String get pageSettingsTitle => 'सैटिंग्स';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'सप्ताह का पहला दिन';

  @override
  String get settingsUseSystemAccentColor => 'Use System Accent Color';

  @override
  String get settingsCustomAccentColor => 'Custom Accent Color';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Show Flashbacks';

  @override
  String get settingsChangeMoodIcons => 'Change Mood Icons';

  @override
  String get moodIconPrompt => 'कोई आइकन इंटर करें';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get settingsHideImagesInGallery => 'Hide Images In Gallery';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'सूचनाएं';

  @override
  String get settingsDailyReminderOnboarding =>
      'Enable daily reminders to keep yourself consistent!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'The \'schedule alarms\' permission will be requested to send the reminder at a random moment or at your preferred time.';

  @override
  String get settingsDailyReminderTitle => 'डेली रिमाइंडर';

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
  String get settingsAlwaysSendReminderTitle => 'हमेशा रिमाइंडर भेजें';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Send reminder even if a log was already started';

  @override
  String get settingsCustomizeNotificationTitle => 'Customize Notifications';

  @override
  String get settingsTemplatesTitle => 'Templates';

  @override
  String get settingsDefaultTemplate => 'डिफ़ॉल्ट टेम्पलेट';

  @override
  String get manageTemplates => 'टेम्पलेट मैनेज करें';

  @override
  String get addTemplate => 'टेम्पलेट जोड़ें';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'None';

  @override
  String get noTemplatesDescription => 'No templates created yet…';

  @override
  String get settingsStorageTitle => 'Storage';

  @override
  String get settingsImageQuality => 'Image Quality';

  @override
  String get imageQualityHigh => 'High';

  @override
  String get imageQualityMedium => 'Medium';

  @override
  String get imageQualityLow => 'Low';

  @override
  String get imageQualityNoCompression => 'No Compression';

  @override
  String get settingsLogFolder => 'Log Folder';

  @override
  String get settingsImageFolder => 'Image Folder';

  @override
  String get warningTitle => 'Warning';

  @override
  String get logFolderWarningDescription =>
      'यदि चयनित फ़ोल्डर में पहले से ही \'daily_you.db\' फ़ाइल मौजूद है, तो इसका उपयोग आपके मौजूदा लॉग को ओवरराइट करने के लिए किया जाएगा!';

  @override
  String get errorTitle => 'Error';

  @override
  String get logFolderErrorDescription => 'Failed to change log folder!';

  @override
  String get imageFolderErrorDescription => 'Failed to change image folder!';

  @override
  String get backupErrorDescription => 'Failed to create backup!';

  @override
  String get restoreErrorDescription => 'Failed to restore backup!';

  @override
  String get settingsBackupRestoreTitle => 'Backup & Restore';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'रीस्टोर';

  @override
  String get settingsRestorePromptDescription =>
      'बैकअप को रीस्टोर करने पर आपके मौजूदा डेटा को ओवरराइट किया जाएगा!';

  @override
  String tranferStatus(Object percent) {
    return 'Transferring… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'बैकअप बनाया जा रहा है... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'बैकअप रीस्टोर किया जा रहा है $percent%';
  }

  @override
  String get cleanUpStatus => 'Cleaning Up…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat =>
      'किसी अन्य फॉर्मेट में निर्यात करें';

  @override
  String get settingsExportFormatDescription =>
      'इसका उपयोग बैकअप के रूप में नहीं किया जाना चाहिए!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'किसी अन्य ऐप से आयात करें';

  @override
  String get settingsTranslateCallToAction =>
      'Everyone should have access to a journal!';

  @override
  String get settingsHelpTranslate => 'Help Translate';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'प्रारूप चुनें';

  @override
  String get logFormatDescription =>
      'अन्य ऐप का प्रारूप सभी फीचर्स को सपोर्ट नहीं कर सकता है। कृपया किसी भी समस्या को रिपोर्ट करें क्योंकि थर्ड पार्टी के प्रारूप कभी भी बदल सकते हैं। यह मौजूदा लॉग को प्रभावित नहीं करेगा!';

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
  String get formatMarkdown => 'मार्कडाउन';

  @override
  String get settingsDeleteAllLogsTitle => 'सभी लॉग हटाएं';

  @override
  String get settingsDeleteAllLogsDescription =>
      'क्या आप अपने सभी लॉग को हटाना चाहते हैं?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Enter \'$prompt\' to confirm. This cannot be undone!';
  }

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsAppLanguageTitle => 'ऐप की भाषा';

  @override
  String get settingsOverrideAppLanguageTitle => 'Override App Language';

  @override
  String get settingsSecurityTitle => 'सिक्योरिटी';

  @override
  String get settingsSecurityRequirePassword => 'पासवर्ड की आवश्यकता है';

  @override
  String get settingsSecurityEnterPassword => 'पासवर्ड दर्ज करें';

  @override
  String get settingsSecuritySetPassword => 'पासवर्ड सेट करें';

  @override
  String get settingsSecurityChangePassword => 'पासवर्ड बदलें';

  @override
  String get settingsSecurityPassword => 'पासवर्ड';

  @override
  String get settingsSecurityConfirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get settingsSecurityOldPassword => 'पुराना पासवर्ड';

  @override
  String get settingsSecurityIncorrectPassword => 'गलत पासवर्ड';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'पासवर्ड मैच नहीं किया';

  @override
  String get requiredPrompt => 'आवश्यक';

  @override
  String get settingsSecurityBiometricUnlock => 'बॉयोमीट्रिक अनलॉक';

  @override
  String get unlockAppPrompt => 'ऐप अनलॉक करें';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsVersion => 'ऐप का वर्जन';

  @override
  String get settingsLicense => 'लाइसेंस';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'स्रोत कोड';

  @override
  String get settingsMadeWithLove => 'Made with ❤️';

  @override
  String get settingsConsiderSupporting => 'consider supporting';

  @override
  String get tagMoodTitle => 'Mood';
}
