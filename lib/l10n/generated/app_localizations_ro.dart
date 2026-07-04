// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Înregistrează-te astăzi!';

  @override
  String get dailyReminderDescription => 'Completează-ți jurnalul zilnic…';

  @override
  String get actionTakePhoto => 'Fă o poză';

  @override
  String get actionToday => 'Astăzi';

  @override
  String get actionOtherDay => 'Altă zi';

  @override
  String get pageHomeTitle => 'Acasă';

  @override
  String get flashbacksTitle => 'Amintiri';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclude zilele proaste';

  @override
  String get flaskbacksEmpty => 'Încă nu ai amintiri…';

  @override
  String get flashbackGoodDay => 'O zi bună';

  @override
  String get flashbackRandomDay => 'O zi aleatorie';

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
  String get flashbackOnThisDay => 'În această zi';

  @override
  String get pageGalleryTitle => 'Galerie';

  @override
  String get searchLogsHint => 'Caută Înregistrări…';

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
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
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
  String get noLogs => 'Nicio Înregistrare…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Crescător';

  @override
  String get sortOrderDescendingTitle => 'Descrescător';

  @override
  String get pageStatisticsTitle => 'Statistici';

  @override
  String get statisticsNotEnoughData => 'Nu există suficiente date…';

  @override
  String get statisticsRangeOneMonth => '1 Lună';

  @override
  String get statisticsRangeSixMonths => '6 Luni';

  @override
  String get statisticsRangeOneYear => '1 An';

  @override
  String get statisticsRangeAllTime => 'Dintotdeauna';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Rezumat';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Pe Zi';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag De-a Lungul Timpului';
  }

  @override
  String get chartGroupingLabel => 'Group by';

  @override
  String get chartGroupingDay => 'Day';

  @override
  String get chartGroupingWeek => 'Week';

  @override
  String get chartGroupingMonth => 'Month';

  @override
  String get chartGroupingYear => 'Year';

  @override
  String get chartSmoothingLabel => 'Smoothing';

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
      'Nu Se Poate Accesa Stocarea Internă';

  @override
  String get errorExternalStorageAccessDescription =>
      'Dacă folosești stocare în rețea, asigură-te că serviciul este online și că ai acces la internet.\n\nÎn caz contrar, este posibil ca aplicația să fi pierdut permisiunile pentru folderul extern. Mergi la setări și selectează din nou folderul extern pentru a-i acorda acces.\n\nAtenție: modificările nu vor fi sincronizate până când nu restabilești accesul la spațiul de stocare extern!';

  @override
  String get errorExternalStorageAccessContinue => 'Continuă Cu Datele Locale';

  @override
  String get lastModified => 'Modificat';

  @override
  String get writeSomethingHint => 'Scrie ceva…';

  @override
  String get titleHint => 'Titlu…';

  @override
  String get deleteLogTitle => 'Șterge Logul';

  @override
  String get deleteLogDescription => 'Dorești să ștergi acest log?';

  @override
  String get deletePhotoTitle => 'Șterge Poză';

  @override
  String get deletePhotoDescription => 'Dorești să ștergi această poză?';

  @override
  String get pageSettingsTitle => 'Setări';

  @override
  String get settingsAppearanceTitle => 'Aspect';

  @override
  String get settingsTheme => 'Temă';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Luminos';

  @override
  String get themeDark => 'Întuncat';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Prima Zi A Săptămânii';

  @override
  String get settingsCalendarSystem => 'Calendar de Sistem';

  @override
  String get calendarSystemGregorian => 'Gregorian';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor =>
      'Folosește Culoarea De Accent A Sistemului';

  @override
  String get settingsCustomAccentColor => 'Culoare De Accent Personalizată';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Arată Amintiri';

  @override
  String get settingsChangeMoodIcons => 'Schimbă Iconițele Pentu Setări';

  @override
  String get moodIconPrompt => 'Introdu o iconiță';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Vizualizare Galerie';

  @override
  String get settingsHideImagesInGallery => 'Ascunde Imaginile În Galerie';

  @override
  String get settingsHideImages => 'Ascunde Imaginile';

  @override
  String get pageCalendarTitle => 'Calendar';

  @override
  String get viewLayoutList => 'Listă';

  @override
  String get viewLayoutGrid => 'Grilă';

  @override
  String get settingsNotificationsTitle => 'Notificări';

  @override
  String get settingsDailyReminderOnboarding =>
      'Activează mementourile zilnice pentru a rămâne consecvent!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Permisiunea „Programare alarme” va fi solicitată pentru a trimite mementoul într-un moment aleatoriu sau la ora preferată.';

  @override
  String get settingsDailyReminderTitle => 'Memento Zilnic';

  @override
  String get settingsOnThisDayDescription => 'Revizitează memoriile din trecut';

  @override
  String get settingsDailyReminderDescription =>
      'O simplă aducere aminte în fiecare zi';

  @override
  String get settingsReminderTime => 'Ora mementoului';

  @override
  String get settingsFixedReminderTimeTitle => 'Oră fixă pentru memento';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Alege o oră fixă pentru memento';

  @override
  String get settingsAlwaysSendReminderTitle => 'Trimite Întotdeauna Memento';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Trimite memento chiar dacă o înregistrare a fost începută deja';

  @override
  String get settingsCustomizeNotificationTitle =>
      'Personalizează Notificările';

  @override
  String get settingsTemplatesTitle => 'Șabloane';

  @override
  String get settingsDefaultTemplate => 'Șablon Implicit';

  @override
  String get manageTemplates => 'Gestionează Șabloane';

  @override
  String get addTemplate => 'Adaugă un Șablon';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'Nici unul';

  @override
  String get noTemplatesDescription => 'Nici un șablon creat încă…';

  @override
  String get templateVariableTime => 'Timp';

  @override
  String get templateDefaultTimestampTitle => 'Marcaj temporal';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Rezumatul Zilei';

  @override
  String get templateDefaultSummaryBody => '### Rezumat\n- \n\n### Citat\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Reflecție';

  @override
  String get templateDefaultReflectionBody =>
      '### What did you enjoy about today?\n- \n\n### What are you thankful for?\n- \n\n### What are you looking forward to?\n- ';

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
      'If the selected folder already contains a \'daily_you.db\' file, it will be used to overwrite your existing logs!';

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
  String get settingsRestore => 'Restore';

  @override
  String get settingsRestorePromptDescription =>
      'Restoring a backup will overwrite your existing data!';

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
  String get settingsHelpTranslate => 'Help Translate';

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
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsAppLanguageTitle => 'App Language';

  @override
  String get settingsOverrideAppLanguageTitle => 'Override App Language';

  @override
  String get settingsSecurityTitle => 'Security';

  @override
  String get settingsSecurityRequirePassword => 'Require Password';

  @override
  String get settingsSecurityEnterPassword => 'Enter Password';

  @override
  String get settingsSecuritySetPassword => 'Set Password';

  @override
  String get settingsSecurityChangePassword => 'Change Password';

  @override
  String get settingsSecurityPassword => 'Password';

  @override
  String get settingsSecurityConfirmPassword => 'Confirm Password';

  @override
  String get settingsSecurityOldPassword => 'Old Password';

  @override
  String get settingsSecurityIncorrectPassword => 'Incorrect Password';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get requiredPrompt => 'Required';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometric Unlock';

  @override
  String get unlockAppPrompt => 'Unlock the app';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'License';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Source Code';

  @override
  String get settingsMadeWithLove => 'Made with ❤️';

  @override
  String get settingsConsiderSupporting => 'consider supporting';

  @override
  String get imagesTitle => 'Images';

  @override
  String get tagMoodTitle => 'Mood';
}
