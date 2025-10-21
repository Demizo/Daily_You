import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_oc.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('id'),
    Locale('it'),
    Locale('nl'),
    Locale('oc'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily You'**
  String get appTitle;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Today!'**
  String get dailyReminderTitle;

  /// No description provided for @dailyReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Take your daily log…'**
  String get dailyReminderDescription;

  /// No description provided for @pageHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get pageHomeTitle;

  /// No description provided for @flashbacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Flashbacks'**
  String get flashbacksTitle;

  /// No description provided for @settingsFlashbacksExcludeBadDays.
  ///
  /// In en, this message translates to:
  /// **'Exclude bad days'**
  String get settingsFlashbacksExcludeBadDays;

  /// No description provided for @flaskbacksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Flashbacks Yet…'**
  String get flaskbacksEmpty;

  /// No description provided for @flashbackGoodDay.
  ///
  /// In en, this message translates to:
  /// **'A Good Day'**
  String get flashbackGoodDay;

  /// No description provided for @flashbackRandomDay.
  ///
  /// In en, this message translates to:
  /// **'A Random Day'**
  String get flashbackRandomDay;

  /// No description provided for @flashbackWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} Week Ago} other{{count} Weeks Ago}}'**
  String flashbackWeek(num count);

  /// No description provided for @flashbackMonth.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} Month Ago} other{{count} Months Ago}}'**
  String flashbackMonth(num count);

  /// No description provided for @flashbackYear.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} Year Ago} other{{count} Years Ago}}'**
  String flashbackYear(num count);

  /// No description provided for @pageGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get pageGalleryTitle;

  /// No description provided for @searchLogsHint.
  ///
  /// In en, this message translates to:
  /// **'Search Logs…'**
  String get searchLogsHint;

  /// No description provided for @logCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} log} other{{count} logs}}'**
  String logCount(num count);

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} word} other{{count} words}}'**
  String wordCount(num count);

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No Logs…'**
  String get noLogs;

  /// No description provided for @sortDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDateTitle;

  /// No description provided for @sortOrderAscendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortOrderAscendingTitle;

  /// No description provided for @sortOrderDescendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortOrderDescendingTitle;

  /// No description provided for @pageStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get pageStatisticsTitle;

  /// No description provided for @statisticsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data…'**
  String get statisticsNotEnoughData;

  /// No description provided for @statisticsRangeOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get statisticsRangeOneMonth;

  /// No description provided for @statisticsRangeSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get statisticsRangeSixMonths;

  /// No description provided for @statisticsRangeOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get statisticsRangeOneYear;

  /// No description provided for @statisticsRangeAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get statisticsRangeAllTime;

  /// No description provided for @chartSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'{tag} Summary'**
  String chartSummaryTitle(Object tag);

  /// No description provided for @chartByDayTitle.
  ///
  /// In en, this message translates to:
  /// **'{tag} By Day'**
  String chartByDayTitle(Object tag);

  /// No description provided for @streakCurrent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Current Streak {count}}}'**
  String streakCurrent(num count);

  /// No description provided for @streakLongest.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Longest Streak {count}}}'**
  String streakLongest(num count);

  /// No description provided for @streakSinceBadDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Days Since a Bad Day {count}}}'**
  String streakSinceBadDay(num count);

  /// No description provided for @errorExternalStorageAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t Access External Storage'**
  String get errorExternalStorageAccessTitle;

  /// No description provided for @errorExternalStorageAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'If you are using network storage make sure the service is online and you have network access.\n\nOtherwise, the app may have lost permissions for the external folder. Go to settings, and reselect the external folder to grant access.\n\nWarning, changes will not be synced until you restore access to the external storage location!'**
  String get errorExternalStorageAccessDescription;

  /// No description provided for @errorExternalStorageAccessContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue With Local Database'**
  String get errorExternalStorageAccessContinue;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get lastModified;

  /// No description provided for @writeSomethingHint.
  ///
  /// In en, this message translates to:
  /// **'Write something…'**
  String get writeSomethingHint;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title…'**
  String get titleHint;

  /// No description provided for @deleteLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Log'**
  String get deleteLogTitle;

  /// No description provided for @deleteLogDescription.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this log?'**
  String get deleteLogDescription;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deletePhotoTitle;

  /// No description provided for @deletePhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this photo?'**
  String get deletePhotoDescription;

  /// No description provided for @pageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pageSettingsTitle;

  /// No description provided for @settingsAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get themeAmoled;

  /// No description provided for @settingsFirstDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'First Day Of Week'**
  String get settingsFirstDayOfWeek;

  /// No description provided for @settingsUseSystemAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Use System Accent Color'**
  String get settingsUseSystemAccentColor;

  /// No description provided for @settingsCustomAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Accent Color'**
  String get settingsCustomAccentColor;

  /// No description provided for @settingsShowMarkdownToolbar.
  ///
  /// In en, this message translates to:
  /// **'Show Markdown Toolbar'**
  String get settingsShowMarkdownToolbar;

  /// No description provided for @settingsShowFlashbacks.
  ///
  /// In en, this message translates to:
  /// **'Show Flashbacks'**
  String get settingsShowFlashbacks;

  /// No description provided for @settingsChangeMoodIcons.
  ///
  /// In en, this message translates to:
  /// **'Change Mood Icons'**
  String get settingsChangeMoodIcons;

  /// No description provided for @moodIconPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter an icon'**
  String get moodIconPrompt;

  /// No description provided for @settingsFlashbacksViewLayout.
  ///
  /// In en, this message translates to:
  /// **'Flashbacks View Layout'**
  String get settingsFlashbacksViewLayout;

  /// No description provided for @settingsGalleryViewLayout.
  ///
  /// In en, this message translates to:
  /// **'Gallery View Layout'**
  String get settingsGalleryViewLayout;

  /// No description provided for @viewLayoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewLayoutList;

  /// No description provided for @viewLayoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewLayoutGrid;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsDailyReminderOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Enable daily reminders to keep yourself consistent!'**
  String get settingsDailyReminderOnboarding;

  /// No description provided for @settingsNotificationsPermissionsPrompt.
  ///
  /// In en, this message translates to:
  /// **'The \'schedule alarms\' permission will be requested to send the reminder at a random moment or at your preferred time.'**
  String get settingsNotificationsPermissionsPrompt;

  /// No description provided for @settingsDailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get settingsDailyReminderTitle;

  /// No description provided for @settingsDailyReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'A gentle reminder each day'**
  String get settingsDailyReminderDescription;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get settingsReminderTime;

  /// No description provided for @settingsFixedReminderTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed Reminder Time'**
  String get settingsFixedReminderTimeTitle;

  /// No description provided for @settingsFixedReminderTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick a fixed time for the reminder'**
  String get settingsFixedReminderTimeDescription;

  /// No description provided for @settingsAlwaysSendReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Always Send Reminder'**
  String get settingsAlwaysSendReminderTitle;

  /// No description provided for @settingsAlwaysSendReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Send reminder even if a log was already started'**
  String get settingsAlwaysSendReminderDescription;

  /// No description provided for @settingsCustomizeNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Notifications'**
  String get settingsCustomizeNotificationTitle;

  /// No description provided for @settingsTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get settingsTemplatesTitle;

  /// No description provided for @settingsDefaultTemplate.
  ///
  /// In en, this message translates to:
  /// **'Default Template'**
  String get settingsDefaultTemplate;

  /// No description provided for @manageTemplates.
  ///
  /// In en, this message translates to:
  /// **'Manage Templates'**
  String get manageTemplates;

  /// No description provided for @addTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add a Template'**
  String get addTemplate;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get newTemplate;

  /// No description provided for @noTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noTemplateTitle;

  /// No description provided for @noTemplatesDescription.
  ///
  /// In en, this message translates to:
  /// **'No templates created yet…'**
  String get noTemplatesDescription;

  /// No description provided for @settingsStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorageTitle;

  /// No description provided for @settingsImageQuality.
  ///
  /// In en, this message translates to:
  /// **'Image Quality'**
  String get settingsImageQuality;

  /// No description provided for @imageQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get imageQualityHigh;

  /// No description provided for @imageQualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get imageQualityMedium;

  /// No description provided for @imageQualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get imageQualityLow;

  /// No description provided for @imageQualityNoCompression.
  ///
  /// In en, this message translates to:
  /// **'No Compression'**
  String get imageQualityNoCompression;

  /// No description provided for @settingsLogFolder.
  ///
  /// In en, this message translates to:
  /// **'Log Folder'**
  String get settingsLogFolder;

  /// No description provided for @settingsImageFolder.
  ///
  /// In en, this message translates to:
  /// **'Image Folder'**
  String get settingsImageFolder;

  /// No description provided for @warningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningTitle;

  /// No description provided for @logFolderWarningDescription.
  ///
  /// In en, this message translates to:
  /// **'If the selected folder already contains a \'daily_you.db\' file, it will be used to overwrite your existing logs!'**
  String get logFolderWarningDescription;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @logFolderErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Failed to change log folder!'**
  String get logFolderErrorDescription;

  /// No description provided for @imageFolderErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Failed to change image folder!'**
  String get imageFolderErrorDescription;

  /// No description provided for @backupErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup!'**
  String get backupErrorDescription;

  /// No description provided for @restoreErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore backup!'**
  String get restoreErrorDescription;

  /// No description provided for @settingsBackupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackupRestoreTitle;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestore;

  /// No description provided for @settingsRestorePromptDescription.
  ///
  /// In en, this message translates to:
  /// **'Restoring a backup will overwrite your existing data!'**
  String get settingsRestorePromptDescription;

  /// No description provided for @tranferStatus.
  ///
  /// In en, this message translates to:
  /// **'Transferring… {percent}%'**
  String tranferStatus(Object percent);

  /// No description provided for @creatingBackupStatus.
  ///
  /// In en, this message translates to:
  /// **'Creating Backup… {percent}%'**
  String creatingBackupStatus(Object percent);

  /// No description provided for @restoringBackupStatus.
  ///
  /// In en, this message translates to:
  /// **'Restoring Backup… {percent}%'**
  String restoringBackupStatus(Object percent);

  /// No description provided for @cleanUpStatus.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Up…'**
  String get cleanUpStatus;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExport;

  /// No description provided for @settingsExportToAnotherFormat.
  ///
  /// In en, this message translates to:
  /// **'Export To Another Format'**
  String get settingsExportToAnotherFormat;

  /// No description provided for @settingsExportFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'This should not be used as a backup!'**
  String get settingsExportFormatDescription;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export Logs'**
  String get exportLogs;

  /// No description provided for @exportImages.
  ///
  /// In en, this message translates to:
  /// **'Export Images'**
  String get exportImages;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImport;

  /// No description provided for @settingsImportFromAnotherApp.
  ///
  /// In en, this message translates to:
  /// **'Import From Another App'**
  String get settingsImportFromAnotherApp;

  /// No description provided for @settingsTranslateCallToAction.
  ///
  /// In en, this message translates to:
  /// **'Everyone should have access to a journal!'**
  String get settingsTranslateCallToAction;

  /// No description provided for @settingsHelpTranslate.
  ///
  /// In en, this message translates to:
  /// **'Help Translate'**
  String get settingsHelpTranslate;

  /// No description provided for @importLogs.
  ///
  /// In en, this message translates to:
  /// **'Import Logs'**
  String get importLogs;

  /// No description provided for @importImages.
  ///
  /// In en, this message translates to:
  /// **'Import Images'**
  String get importImages;

  /// No description provided for @logFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Format'**
  String get logFormatTitle;

  /// No description provided for @logFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'Another app\'s format may not support all features. Please report any issues since third party formats may change at any time. This will not impact existing logs!'**
  String get logFormatDescription;

  /// No description provided for @formatDailyYouJson.
  ///
  /// In en, this message translates to:
  /// **'Daily You (JSON)'**
  String get formatDailyYouJson;

  /// No description provided for @formatDaylio.
  ///
  /// In en, this message translates to:
  /// **'Daylio'**
  String get formatDaylio;

  /// No description provided for @formatDiarium.
  ///
  /// In en, this message translates to:
  /// **'Diarium'**
  String get formatDiarium;

  /// No description provided for @formatMyBrain.
  ///
  /// In en, this message translates to:
  /// **'My Brain'**
  String get formatMyBrain;

  /// No description provided for @formatOneShot.
  ///
  /// In en, this message translates to:
  /// **'OneShot'**
  String get formatOneShot;

  /// No description provided for @formatPixels.
  ///
  /// In en, this message translates to:
  /// **'Pixels'**
  String get formatPixels;

  /// No description provided for @formatMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get formatMarkdown;

  /// No description provided for @settingsDeleteAllLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Logs'**
  String get settingsDeleteAllLogsTitle;

  /// No description provided for @settingsDeleteAllLogsDescription.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete all of your logs?'**
  String get settingsDeleteAllLogsDescription;

  /// No description provided for @settingsDeleteAllLogsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter \'{prompt}\' to confirm. This cannot be undone!'**
  String settingsDeleteAllLogsPrompt(Object prompt);

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsAppLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsAppLanguageTitle;

  /// No description provided for @settingsOverrideAppLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Override App Language'**
  String get settingsOverrideAppLanguageTitle;

  /// No description provided for @settingsSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurityTitle;

  /// No description provided for @settingsSecurityRequirePassword.
  ///
  /// In en, this message translates to:
  /// **'Require Password'**
  String get settingsSecurityRequirePassword;

  /// No description provided for @settingsSecurityEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get settingsSecurityEnterPassword;

  /// No description provided for @settingsSecuritySetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get settingsSecuritySetPassword;

  /// No description provided for @settingsSecurityChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsSecurityChangePassword;

  /// No description provided for @settingsSecurityPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsSecurityPassword;

  /// No description provided for @settingsSecurityConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get settingsSecurityConfirmPassword;

  /// No description provided for @settingsSecurityOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get settingsSecurityOldPassword;

  /// No description provided for @settingsSecurityIncorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Password'**
  String get settingsSecurityIncorrectPassword;

  /// No description provided for @settingsSecurityPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get settingsSecurityPasswordsDoNotMatch;

  /// No description provided for @requiredPrompt.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredPrompt;

  /// No description provided for @settingsSecurityBiometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get settingsSecurityBiometricUnlock;

  /// No description provided for @unlockAppPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock the app'**
  String get unlockAppPrompt;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settingsLicense;

  /// No description provided for @licenseGPLv3.
  ///
  /// In en, this message translates to:
  /// **'GPL-3.0'**
  String get licenseGPLv3;

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get settingsSourceCode;

  /// No description provided for @settingsMadeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️'**
  String get settingsMadeWithLove;

  /// No description provided for @settingsConsiderSupporting.
  ///
  /// In en, this message translates to:
  /// **'consider supporting'**
  String get settingsConsiderSupporting;

  /// No description provided for @tagMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get tagMoodTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'cs',
        'da',
        'de',
        'en',
        'es',
        'fi',
        'fr',
        'he',
        'id',
        'it',
        'nl',
        'oc',
        'pl',
        'pt',
        'ru',
        'tr',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'oc':
      return AppLocalizationsOc();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
