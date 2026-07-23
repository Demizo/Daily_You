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
  String get dailyReminderTitle => 'Heute eintragen!';

  @override
  String get dailyReminderDescription => 'Mache deinen Eintrag …';

  @override
  String get actionTakePhoto => 'Foto machen';

  @override
  String get actionToday => 'Heute';

  @override
  String get actionOtherDay => 'Anderer Tag';

  @override
  String get pageHomeTitle => 'Start';

  @override
  String get jumpToMonthTitle => 'Springe zu Monat';

  @override
  String get jumpToLogTitle => 'Wechsle zum Log';

  @override
  String get flashbacksTitle => 'Rückblicke';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Schließe schlechte Tage aus';

  @override
  String get flaskbacksEmpty => 'Bis jetzt keine Rückblicke…';

  @override
  String get flashbackGoodDay => 'Ein guter Tag';

  @override
  String get flashbackRandomDay => 'Ein zufälliger Tag';

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
  String get flashbackOnThisDay => 'An diesem Tag';

  @override
  String get pageGalleryTitle => 'Galerie';

  @override
  String get searchLogsHint => 'Einträge durchsuchen …';

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
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '$count Tag',
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
  String get noLogs => 'Keine Einträge vorhanden …';

  @override
  String get noResults => 'No Results…';

  @override
  String get sortDateTitle => 'Datum';

  @override
  String get sortOrderAscendingTitle => 'Aufsteigend';

  @override
  String get sortOrderDescendingTitle => 'Absteigend';

  @override
  String get pageStatisticsTitle => 'Statistiken';

  @override
  String get statisticsNotEnoughData => 'Nicht genügend Daten …';

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
    return '$tag pro Tag';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag Über die Zeit';
  }

  @override
  String get chartGroupingLabel => 'Gruppieren nach';

  @override
  String get chartGroupingDay => 'Tag';

  @override
  String get chartGroupingWeek => 'Woche';

  @override
  String get chartGroupingMonth => 'Monat';

  @override
  String get chartGroupingYear => 'Jahr';

  @override
  String get chartSmoothingLabel => 'Glättung';

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
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Great Days $count',
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
  String get settingsTheme => 'Farbschema';

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
  String get settingsCalendarSystem => 'Kalendersystem';

  @override
  String get calendarSystemGregorian => 'Gregorianisch';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor => 'System-Akzentfarbe verwenden';

  @override
  String get settingsCustomAccentColor => 'Eigene Akzentfarbe';

  @override
  String get settingsShowMarkdownToolbar => 'Zeige Markdown Werkzeugleiste';

  @override
  String get settingsShowFlashbacks => 'Zeige Rückblicke';

  @override
  String get settingsChangeMoodIcons => 'Stimmung-Symbole ändern';

  @override
  String get moodIconPrompt => 'Symbol hier eingeben';

  @override
  String get settingsFlashbacksViewLayout => 'Layout der Rückblicksansicht';

  @override
  String get settingsGalleryViewLayout => 'Galerieansichts-Layout';

  @override
  String get settingsHideImagesInGallery => 'Bilder in der Galerie verbergen';

  @override
  String get settingsHideImages => 'Bilder verbergen';

  @override
  String get pageCalendarTitle => 'Kalender';

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
  String get settingsOnThisDayDescription => 'Erlebe alte Erinnerungen neu';

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
  String get noTemplatesDescription => 'Noch keine Vorlagen erstellt…';

  @override
  String get templateVariableTime => 'Uhrzeit';

  @override
  String get templateDefaultTimestampTitle => 'Zeitstempel';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Tageszusammenfassung';

  @override
  String get templateDefaultSummaryBody =>
      '### Zusammenfassung\n- \n\n### Zitat\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Rückblick';

  @override
  String get templateDefaultReflectionBody =>
      '### Was hat dir heute spaß gemachty?\n- \n\n### Wofür bist du heute Dankbar?\n- \n\n### Worauf Freist du dich?\n- ';

  @override
  String get settingsTagsTitle => 'Tags';

  @override
  String get manageTags => 'Manage Tags';

  @override
  String get tagTypeLabelTitle => 'Label';

  @override
  String get tagTypeTrackerTitle => 'Tracker';

  @override
  String get tagNameHint => 'Tag name';

  @override
  String get tagColorLabel => 'Color';

  @override
  String get tagIconLabel => 'Icon';

  @override
  String get iconPickerTitle => 'Choose Icon';

  @override
  String get iconPickerIconsTab => 'Icons';

  @override
  String get iconPickerCustomTab => 'Custom';

  @override
  String get iconPickerSearchHint => 'Search icons';

  @override
  String get colorPickerTitle => 'Choose Color';

  @override
  String get colorPickerPaletteTab => 'Colors';

  @override
  String get colorPickerNoneOption => 'None';

  @override
  String get colorPickerCustomTab => 'Custom';

  @override
  String get iconGroupMoodPeople => 'Mood & People';

  @override
  String get iconGroupHealth => 'Health';

  @override
  String get iconGroupWorkFinance => 'Work & Finance';

  @override
  String get iconGroupHabitsGoals => 'Habits & Goals';

  @override
  String get iconGroupNature => 'Nature';

  @override
  String get iconGroupFoodDrink => 'Food & Drink';

  @override
  String get iconGroupTravel => 'Travel';

  @override
  String get iconGroupSymbols => 'Symbols';

  @override
  String get tagTypeLabel => 'Type';

  @override
  String get editTagTitle => 'Edit Tag';

  @override
  String get newTagTitle => 'New Tag';

  @override
  String get tagCategoryLabel => 'Category';

  @override
  String get tagCategoryNone => 'None';

  @override
  String get tagCategoryUncategorized => 'Uncategorized';

  @override
  String get newCategoryTitle => 'New Category';

  @override
  String get editCategoryTitle => 'Edit Category';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get deleteTagTitle => 'Delete Tag?';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '$count log',
    );
    return 'Delete \"$name\"? Used in $_temp0.';
  }

  @override
  String get deleteCategoryTitle => 'Delete Category?';

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '$count tag',
    );
    return '\"$name\" contains $_temp0. What should happen to them?';
  }

  @override
  String get deleteCategoryOnlyButton => 'Category only';

  @override
  String get deleteCategoryAndTagsButton => 'Category and all tags';

  @override
  String get filterTagsTitle => 'Filter';

  @override
  String get tagFilterModeAny => 'Any Tag';

  @override
  String get tagFilterModeAll => 'All Tags';

  @override
  String get clearAllFilters => 'Clear All';

  @override
  String get noTagsFilterLabel => 'No Tags';

  @override
  String get trackerSortLabel => 'Sort by tracker';

  @override
  String get addTagsTitle => 'Add Tags';

  @override
  String get addTagsSearchHint => 'Search tags…';

  @override
  String get addTagButton => 'Add';

  @override
  String get tagPickerSortManualLabel => 'Manual order';

  @override
  String get tagPickerSortUsageLabel => 'Sort by usage';

  @override
  String get trackerValueTitle => 'Set Value';

  @override
  String get trackerValueHint => 'Value';

  @override
  String get trackerFrequentValues => 'Frequent values';

  @override
  String get tagFavoriteName => 'Favorite';

  @override
  String get tagEnergyName => 'Energy';

  @override
  String get tagCategoryActivitiesName => 'Activities';

  @override
  String get tagExerciseName => 'Exercise';

  @override
  String get tagSocializingName => 'Socializing';

  @override
  String get tagHobbyName => 'Hobby';

  @override
  String get tagEntertainmentName => 'Entertainment';

  @override
  String get tagDiningName => 'Dining';

  @override
  String get tagChoresName => 'Chores';

  @override
  String get tagCategoryEmotionsName => 'Emotions';

  @override
  String get tagExcitedName => 'Excited';

  @override
  String get tagGratefulName => 'Grateful';

  @override
  String get tagCalmName => 'Calm';

  @override
  String get tagTiredName => 'Tired';

  @override
  String get tagAnxiousName => 'Anxious';

  @override
  String get tagAnnoyedName => 'Annoyed';

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
  String get imageQualityNoCompression => 'Keine Komprimierung';

  @override
  String get settingsLogFolder => 'Einträge Ordner';

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
      'Wiederherstellung einer Sicherung überschreibt vorhandene Daten!';

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
      'Jede*r sollte das Recht auf einen Eintrag haben!';

  @override
  String get settingsHelpTranslate => 'Hilf übersetzen';

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
      'Passwörter sind nicht identisch';

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
  String get imagesTitle => 'Bilder';

  @override
  String get tagMoodTitle => 'Stimmung';

  @override
  String get calendarViewOptionsTitle => 'Display Options';

  @override
  String get calendarTagDisplayLabel => 'Tag';

  @override
  String get selectTagTitle => 'Select Tag';

  @override
  String get labelPresentLabel => 'Present';

  @override
  String get labelAbsentLabel => 'Absent';

  @override
  String get labelCoverageLabel => 'Coverage';

  @override
  String chartDistributionTitle(Object tag) {
    return '$tag Distribution';
  }
}
