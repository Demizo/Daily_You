// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Heute Eintragen!';

  @override
  String get dailyReminderDescription => 'Mache deinen Eintrag…';

  @override
  String get pageHomeTitle => 'Start';

  @override
  String get flashbacksTitle => 'Rückblicke';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Schließe schlechte Tage aus';

  @override
  String get flaskbacksEmpty => 'Bis jetzt keine Rückblicke…';

  @override
  String get flashbackGoodDay => 'Ein Guter Tag';

  @override
  String get flashbackRandomDay => 'Ein Zufälliger Tag';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wochen her',
      one: '$count Woche her',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Monate her',
      one: '$count Monat her',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jahre her',
      one: '$count Jahr her',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Galerie';

  @override
  String get searchLogsHint => 'Durchsuchen der Einträge …';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '$count Eintrag',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '$count Wort',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Keine Einträge vorhanden …';

  @override
  String get sortDateTitle => 'Datum';

  @override
  String get sortOrderAscendingTitle => 'Aufsteigend';

  @override
  String get sortOrderDescendingTitle => 'Absteigend';

  @override
  String get pageStatisticsTitle => 'Statistiken';

  @override
  String get statisticsNotEnoughData => 'Nicht genügend Daten…';

  @override
  String get statisticsRangeOneMonth => '1 Monat';

  @override
  String get statisticsRangeSixMonths => '6 Monate';

  @override
  String get statisticsRangeOneYear => '1 Jahr';

  @override
  String get statisticsRangeAllTime => 'Gesamt';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Übersicht';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Pro Tag';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aktuell Serie $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Längste Serie $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage seit einem schlechten Tag $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Kann nicht auf externen Speicher zugreifen';

  @override
  String get errorExternalStorageAccessDescription =>
      'Wenn Sie Netzwerkspeicher verwenden, stellen Sie sicher, dass der Dienst online ist und Sie Zugriff auf das Netzwerk haben.\n\nAndernfalls hat die App möglicherweise die Berechtigungen für den externen Ordner verloren. Gehen Sie zu den Einstellungen und wählen Sie den externen Ordner erneut aus, um den Zugriff zu gewähren.\n\nAchtung: Änderungen werden erst synchronisiert, wenn Sie den Zugriff auf den externen Speicherort wiederherstellen!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Weiter mit lokaler Datenbank';

  @override
  String get lastModified => 'Geändert';

  @override
  String get writeSomethingHint => 'Schreibe etwas …';

  @override
  String get titleHint => 'Titel…';

  @override
  String get deleteLogTitle => 'Eintrag löschen';

  @override
  String get deleteLogDescription => 'Möchtest du diesen Eintrag löschen?';

  @override
  String get deletePhotoTitle => 'Foto löschen';

  @override
  String get deletePhotoDescription => 'Möchtest du das Foto löschen?';

  @override
  String get pageSettingsTitle => 'Einstellungen';

  @override
  String get settingsAppearanceTitle => 'Aussehen';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Erster Tag der Woche';

  @override
  String get settingsUseSystemAccentColor => 'System Akzentfarbe Verwenden';

  @override
  String get settingsCustomAccentColor => 'Eigene Akzentfarbe';

  @override
  String get settingsShowMarkdownToolbar => 'Zeige Markdown Werkzeugleiste';

  @override
  String get settingsShowFlashbacks => 'Zeige Rückblicke';

  @override
  String get settingsChangeMoodIcons => 'Ändere Mood Icons';

  @override
  String get moodIconPrompt => 'Icon hier eingeben';

  @override
  String get settingsFlashbacksViewLayout => 'Layout der Rückblicksansicht';

  @override
  String get settingsGalleryViewLayout => 'Galerieansichts-Layout';

  @override
  String get settingsHideImagesInGallery => 'Hide Images In Gallery';

  @override
  String get viewLayoutList => 'Liste';

  @override
  String get viewLayoutGrid => 'Raster';

  @override
  String get settingsNotificationsTitle => 'Benachrichtigung';

  @override
  String get settingsDailyReminderOnboarding =>
      'Aktivieren Sie tägliche Erinnerungen um Konstant Einträge zu machen!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Die Berechtigung \"Planen von genauen Weckern\" wird angefragt, um eine Errinnerung an dich zu einer zufälligen Zeit oder zu deiner ausgewählten Zeit zu senden.';

  @override
  String get settingsDailyReminderTitle => 'Tägliche Erinnerung';

  @override
  String get settingsDailyReminderDescription =>
      'Eine kleine Erinnerung jeden Tag';

  @override
  String get settingsReminderTime => 'Erinnerungszeit';

  @override
  String get settingsFixedReminderTimeTitle => 'Feste Erinnerungszeit';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Wähle eine feste Zeit für die Erinnerung';

  @override
  String get settingsAlwaysSendReminderTitle => 'Erinnerung immer zeigen';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Sende Erinnerungen, auch wenn ein Eintrag schon angefangen wurde';

  @override
  String get settingsCustomizeNotificationTitle =>
      'Benachrichtigungen Bearbeiten';

  @override
  String get settingsTemplatesTitle => 'Vorlagen';

  @override
  String get settingsDefaultTemplate => 'Standardvorlage';

  @override
  String get manageTemplates => 'Vorlagen verwalten';

  @override
  String get addTemplate => 'Vorlage hinzufügen';

  @override
  String get newTemplate => 'Neu Vorlage';

  @override
  String get noTemplateTitle => 'Keine';

  @override
  String get noTemplatesDescription => 'Noch kein Vorlagen erstellt…';

  @override
  String get settingsStorageTitle => 'Speicher';

  @override
  String get settingsImageQuality => 'Bildqualität';

  @override
  String get imageQualityHigh => 'Hoch';

  @override
  String get imageQualityMedium => 'Mittel';

  @override
  String get imageQualityLow => 'Niedrig';

  @override
  String get imageQualityNoCompression => 'keine Komprimierung';

  @override
  String get settingsLogFolder => 'Eintrags Ordner';

  @override
  String get settingsImageFolder => 'Bild Ordner';

  @override
  String get warningTitle => 'Achtung';

  @override
  String get logFolderWarningDescription =>
      'Wenn der ausgewählte Ordner bereits eine \'daily_you.db\'-Datei enthält, wird diese verwendet, um Ihre bestehenden Einträge zu überschreiben!';

  @override
  String get errorTitle => 'Fehler';

  @override
  String get logFolderErrorDescription =>
      'Eintragsordneränderung fehlgeschlagen!';

  @override
  String get imageFolderErrorDescription =>
      'Bilderordneränderung fehlgeschlagen!';

  @override
  String get backupErrorDescription => 'Sicherung Fehlgeschlagen!';

  @override
  String get restoreErrorDescription =>
      'Wiederherstellung der Sicherung Fehlgeschlagen!';

  @override
  String get settingsBackupRestoreTitle => 'Sichern & Wiederherstellen';

  @override
  String get settingsBackup => 'Sicherung';

  @override
  String get settingsRestore => 'Wiederherstellen';

  @override
  String get settingsRestorePromptDescription =>
      'Eine Sicherung wiederherzustellen löscht alle bisherigen Daten!';

  @override
  String tranferStatus(Object percent) {
    return 'Übertragen... $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Erstelle Backup... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Stelle Sicherung wieder her... $percent%';
  }

  @override
  String get cleanUpStatus => 'Aufräumen…';

  @override
  String get settingsExport => 'Exportieren';

  @override
  String get settingsExportToAnotherFormat => 'In anderes Format exportieren';

  @override
  String get settingsExportFormatDescription =>
      'Das sollte nicht als Backup verwendet werden!';

  @override
  String get exportLogs => 'Einträge Exportieren';

  @override
  String get exportImages => 'Bilder Exportieren';

  @override
  String get settingsImport => 'Importieren';

  @override
  String get settingsImportFromAnotherApp => 'Aus anderen App importieren';

  @override
  String get settingsTranslateCallToAction =>
      'Jede*r sollte das Recht auf ein Eintrag haben!';

  @override
  String get settingsHelpTranslate => 'Hilf Übersetzen';

  @override
  String get importLogs => 'Einträge Importieren';

  @override
  String get importImages => 'Bilder Importieren';

  @override
  String get logFormatTitle => 'Format Auswählen';

  @override
  String get logFormatDescription =>
      'Die Formate anderer Apps könnten ggf. nicht alle Funktionen beinhalten. Bitte melde alle Probleme, da Formate anderer Apps sich jederzeit ändern können. Das wird sich nicht auf aktuelle Einträge auswirken!';

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
  String get settingsDeleteAllLogsTitle => 'Alle Einträge löschen';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Möchtest du alle Einträge löschen?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Zum Bestätigen gib \'$prompt\' ein. Das kann nicht rückgängig gemacht werden!';
  }

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsAppLanguageTitle => 'App Sprache';

  @override
  String get settingsOverrideAppLanguageTitle => 'Überschreibe App Sprache';

  @override
  String get settingsSecurityTitle => 'Sicherheit';

  @override
  String get settingsSecurityRequirePassword => 'Benötige Passwort';

  @override
  String get settingsSecurityEnterPassword => 'Passwort eingeben';

  @override
  String get settingsSecuritySetPassword => 'Passwort setzen';

  @override
  String get settingsSecurityChangePassword => 'Ändere Passwort';

  @override
  String get settingsSecurityPassword => 'Passwort';

  @override
  String get settingsSecurityConfirmPassword => 'Bestätige Passwort';

  @override
  String get settingsSecurityOldPassword => 'Altes Passwort';

  @override
  String get settingsSecurityIncorrectPassword => 'Falsches Passwort';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Passwörter sind nicht gleich';

  @override
  String get requiredPrompt => 'Notwendig';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometrisch Entsperren';

  @override
  String get unlockAppPrompt => 'App entsperren';

  @override
  String get settingsAboutTitle => 'Über';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'Lizenz';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Quellcode';

  @override
  String get settingsMadeWithLove => 'Mit ❤️ gemacht';

  @override
  String get settingsConsiderSupporting => 'unterstützen';

  @override
  String get tagMoodTitle => 'Stimmung';
}
