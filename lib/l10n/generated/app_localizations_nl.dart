// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Log vandaag!';

  @override
  String get dailyReminderDescription => 'Schrijf je dagelijkse log…';

  @override
  String get pageHomeTitle => 'Start';

  @override
  String get flashbacksTitle => 'Terugblikken';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Sluit slechte dagen uit';

  @override
  String get flaskbacksEmpty => 'Nog geen terugblikken…';

  @override
  String get flashbackGoodDay => 'Een goede dag';

  @override
  String get flashbackRandomDay => 'Een willekeurige dag';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weken geleden',
      one: '$count week geleden',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maanden geleden',
      one: '$count maand geleden',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jaren geleden',
      one: '$count jaar geleden',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Galerij';

  @override
  String get searchLogsHint => 'Doorzoek logboeken…';

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
      other: '$count woorden',
      one: '$count woord',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Geen logs te tonen…';

  @override
  String get sortDateTitle => 'Datum';

  @override
  String get sortOrderAscendingTitle => 'Oplopend';

  @override
  String get sortOrderDescendingTitle => 'Aflopend';

  @override
  String get pageStatisticsTitle => 'Statistieken';

  @override
  String get statisticsNotEnoughData => 'Niet genoeg data…';

  @override
  String get statisticsRangeOneMonth => '1 maand';

  @override
  String get statisticsRangeSixMonths => '6 maanden';

  @override
  String get statisticsRangeOneYear => '1 jaar';

  @override
  String get statisticsRangeAllTime => 'Alles';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Samenvatting';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag per dag';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Huidige reeks $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Langste reeks $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dagen sinds een slechte dag $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Geen toegang tot externe opslag';

  @override
  String get errorExternalStorageAccessDescription =>
      'Als je netwerkopslag gebruikt, zorg ervoor dat de service online is en dat je netwerktoegang hebt.\n\nHet kan ook zijn dat de app privileges voor de externe map is verloren. Ga naar instellingen en selecteer de externe map om toegang te geven.\n\nWaarschuwing, veranderingen worden niet gesynchroniseerd totdat je toegang tot de externe opslag hersteld!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Ga door met lokale database';

  @override
  String get lastModified => 'Gewijzigd';

  @override
  String get writeSomethingHint => 'Schrijf iets op…';

  @override
  String get titleHint => 'Titel…';

  @override
  String get deleteLogTitle => 'Verwijder log';

  @override
  String get deleteLogDescription =>
      'Weet je zeker dat je deze log wil verwijderen?';

  @override
  String get deletePhotoTitle => 'Verwijder foto';

  @override
  String get deletePhotoDescription =>
      'Weet je zeker dat je deze foto wil verwijderen?';

  @override
  String get pageSettingsTitle => 'Instellingen';

  @override
  String get settingsAppearanceTitle => 'Uiterlijk';

  @override
  String get settingsTheme => 'Thema';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Eerste dag van de week';

  @override
  String get settingsUseSystemAccentColor =>
      'Gebruik accentkleur van het systeem';

  @override
  String get settingsCustomAccentColor => 'Eigen accentkleur';

  @override
  String get settingsShowMarkdownToolbar => 'Toon Markdown werkbalk';

  @override
  String get settingsShowFlashbacks => 'Toon terugblikken';

  @override
  String get settingsChangeMoodIcons => 'Wijzig humeuriconen';

  @override
  String get moodIconPrompt => 'Voer een icoon in';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Raster';

  @override
  String get settingsNotificationsTitle => 'Meldingen';

  @override
  String get settingsDailyReminderOnboarding =>
      'Zet dagelijkse herinneringen aan om consistent te blijven!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'De \'plan alarmen\' toestemming zal aangevraagd worden om de herinnering op een willekeurig moment of op je gewenste tijd te sturen.';

  @override
  String get settingsDailyReminderTitle => 'Dagelijkse herinnering';

  @override
  String get settingsDailyReminderDescription =>
      'Iedere dag een kleine herinnering';

  @override
  String get settingsReminderTime => 'Herinneringstijd';

  @override
  String get settingsFixedReminderTimeTitle => 'Vaste herinneringstijd';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Kies een vaste tijd voor de herinnering';

  @override
  String get settingsAlwaysSendReminderTitle => 'Stuur altijd een herinnering';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Stuur ook een herinnering als er al gelogd is';

  @override
  String get settingsCustomizeNotificationTitle => 'Meldingen aanpassen';

  @override
  String get settingsTemplatesTitle => 'Sjablonen';

  @override
  String get settingsDefaultTemplate => 'Standaardsjabloon';

  @override
  String get manageTemplates => 'Sjablonen beheren';

  @override
  String get addTemplate => 'Sjabloon toevoegen';

  @override
  String get newTemplate => 'Nieuw sjabloon';

  @override
  String get noTemplateTitle => 'Geen';

  @override
  String get noTemplatesDescription => 'Nog geen sjablonen aangemaakt…';

  @override
  String get settingsStorageTitle => 'Opslag';

  @override
  String get settingsImageQuality => 'Afbeeldingskwaliteit';

  @override
  String get imageQualityHigh => 'Hoog';

  @override
  String get imageQualityMedium => 'Middel';

  @override
  String get imageQualityLow => 'Laag';

  @override
  String get imageQualityNoCompression => 'Geen compressie';

  @override
  String get settingsLogFolder => 'Logmap';

  @override
  String get settingsImageFolder => 'Afbeeldingsmap';

  @override
  String get warningTitle => 'Waarschuwing';

  @override
  String get logFolderWarningDescription =>
      'Als de geselecteerde map al een \'daily_you.db\' bestand bevat, zal het gebruikt worden om je bestaande logs te overschrijven!';

  @override
  String get errorTitle => 'Fout';

  @override
  String get logFolderErrorDescription => 'Kan de logmap niet wijzigen!';

  @override
  String get imageFolderErrorDescription =>
      'Kan de afbeeldingsmap niet wijzigen!';

  @override
  String get backupErrorDescription => 'Kan geen back-up maken!';

  @override
  String get restoreErrorDescription => 'Kan back-up niet herstellen!';

  @override
  String get settingsBackupRestoreTitle => 'Back-up & Herstellen';

  @override
  String get settingsBackup => 'Back-up';

  @override
  String get settingsRestore => 'Herstellen';

  @override
  String get settingsRestorePromptDescription =>
      'Het herstellen van een back-up zal je huidige data overschrijven!';

  @override
  String tranferStatus(Object percent) {
    return 'Overzetten... $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Back-up maken... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Back-up herstellen... $percent%';
  }

  @override
  String get cleanUpStatus => 'Schoonmaken…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat =>
      'Exporteren naar een ander formaat';

  @override
  String get settingsExportFormatDescription =>
      'Dit zou niet als een back-up gebruikt moeten worden!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importeer vanuit een andere app';

  @override
  String get settingsTranslateCallToAction =>
      'Iedereen zou toegang tot een dagboek moeten hebben!';

  @override
  String get settingsHelpTranslate => 'Help vertalen';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Kies formaat';

  @override
  String get logFormatDescription =>
      'Het formaat van een andere app ondersteunt mogelijk niet alle functies. Meld eventuele problemen, aangezien formaten van derden op ieder moment kunnen veranderen. Dit heeft geen invloed op bestaande logs!';

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
  String get settingsDeleteAllLogsTitle => 'Verwijder alle logs';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Weet je zeker dat je alle logs wilt verwijderen?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Voer \'$prompt\' in om te bevestigen. Dit kan niet ongedaan worden gemaakt!';
  }

  @override
  String get settingsLanguageTitle => 'Taal';

  @override
  String get settingsAppLanguageTitle => 'Taal van de app';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Overschrijf de taal van de app';

  @override
  String get settingsSecurityTitle => 'Beveiliging';

  @override
  String get settingsSecurityRequirePassword => 'Vereis wachtwoord';

  @override
  String get settingsSecurityEnterPassword => 'Voer wachtwoord in';

  @override
  String get settingsSecuritySetPassword => 'Stel wachtwoord in';

  @override
  String get settingsSecurityChangePassword => 'Verander wachtwoord';

  @override
  String get settingsSecurityPassword => 'Wachtwoord';

  @override
  String get settingsSecurityConfirmPassword => 'Bevestig wachtwoord';

  @override
  String get settingsSecurityOldPassword => 'Oud wachtwoord';

  @override
  String get settingsSecurityIncorrectPassword => 'Onjuist wachtwoord';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Wachtwoorden komen niet overeen';

  @override
  String get requiredPrompt => 'Vereist';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometrische ontgrendeling';

  @override
  String get unlockAppPrompt => 'Ontgrendel de app';

  @override
  String get settingsAboutTitle => 'Over';

  @override
  String get settingsVersion => 'Versie';

  @override
  String get settingsLicense => 'Licentie';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Broncode';

  @override
  String get settingsMadeWithLove => 'Gemaakt met ❤️';

  @override
  String get settingsConsiderSupporting => 'overweeg te ondersteunen';

  @override
  String get tagMoodTitle => 'Humeur';
}
