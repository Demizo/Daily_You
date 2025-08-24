// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Wpisz się!';

  @override
  String get dailyReminderDescription => 'Zrób dzisiejszy wpis…';

  @override
  String get pageHomeTitle => 'Strona domowa';

  @override
  String get flashbacksTitle => 'Wspomnienia';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Wyklucz złe dni';

  @override
  String get flaskbacksEmpty => 'Brak dodanych wspomnień…';

  @override
  String get flashbackGoodDay => 'Dobry dzień';

  @override
  String get flashbackRandomDay => 'Losowy dzień';

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
  String get pageGalleryTitle => 'Galeria';

  @override
  String get searchLogsHint => 'Szukaj wpisu…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ilość wpisów',
      one: '$count log',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count słowa',
      one: '$count word',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Brak wpisu…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Rosnąco';

  @override
  String get sortOrderDescendingTitle => 'Malejąco';

  @override
  String get pageStatisticsTitle => 'Statystyki';

  @override
  String get statisticsNotEnoughData => 'Zbyt mało danych…';

  @override
  String get statisticsRangeOneMonth => '1 miesiąc';

  @override
  String get statisticsRangeSixMonths => '6 miesięcy';

  @override
  String get statisticsRangeOneYear => '1 rok';

  @override
  String get statisticsRangeAllTime => 'Cały okres';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag - Podsumowanie';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aktualna passa $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Najdłuższa passa $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dni od złego dnia$count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Nie można uzyskać dostępu do pamięci zewnętrznej';

  @override
  String get errorExternalStorageAccessDescription =>
      'Jeśli używasz pamięci sieciowej, upewnij się czy usługa jest online i czy masz połączenie z internetem.\n\nW innym wypadku aplikacja mogła stracić uprawnienia do zewnętrznego folderu. Idź do ustawień i ponownie wybierz zewnętrzny folder by uzyskać uprawnienia.\n\nUwaga, zmiany nie zostaną zsynchronizowane dopóki nie przywrócisz dostępu do lokalizacji pamięci zewnętrznej!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Kontynuuj z lokalną bazą danych';

  @override
  String get lastModified => 'Zmodyfikowane';

  @override
  String get writeSomethingHint => 'Napisz coś…';

  @override
  String get titleHint => 'Tytuł…';

  @override
  String get deleteLogTitle => 'Usuń wpis';

  @override
  String get deleteLogDescription => 'Czy chcesz usunąć ten wpis?';

  @override
  String get deletePhotoTitle => 'Usuń zdjęcie';

  @override
  String get deletePhotoDescription => 'Czy chcesz usunąć to zdjęcie?';

  @override
  String get pageSettingsTitle => 'Ustawienia';

  @override
  String get settingsAppearanceTitle => 'Wygląd';

  @override
  String get settingsTheme => 'Motyw';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Pierwszy dzień tygodnia';

  @override
  String get settingsUseSystemAccentColor => 'Użyj systemowego koloru akcentu';

  @override
  String get settingsCustomAccentColor => 'Własny kolor akcentu';

  @override
  String get settingsShowMarkdownToolbar => 'Pokaż pasek narzędzi';

  @override
  String get settingsShowFlashbacks => 'Pokaż wspomnienia';

  @override
  String get settingsChangeMoodIcons => 'Pokaż ikony nastroju';

  @override
  String get moodIconPrompt => 'Wprowadź ikonę';

  @override
  String get settingsNotificationsTitle => 'Powiadomienia';

  @override
  String get settingsDailyReminderOnboarding =>
      'Włącz codzienne przypomnienia by utrzymać swoją konsekwentność!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Uprawnienie \'alarmy i przypomnienia\' jest wymagane, by wysyłać powiadomienia o ustalonym lub losowym czasie.';

  @override
  String get settingsDailyReminderTitle => 'Codzienne przypomnienie';

  @override
  String get settingsDailyReminderDescription =>
      'Subtelne przypomnienie każdego dnia';

  @override
  String get settingsReminderTime => 'Czas przypomnienia';

  @override
  String get settingsFixedReminderTimeTitle => 'Stały czas przypomnienia';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Ustaw niezmienny czas przypomnienia';

  @override
  String get settingsAlwaysSendReminderTitle => 'Zawsze wysyłaj powiadomienie';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Wyślij powiadomienie nawet jeśli wpis został rozpoczęty';

  @override
  String get settingsCustomizeNotificationTitle => 'Modyfikuj powiadomienia';

  @override
  String get settingsTemplatesTitle => 'Szablony';

  @override
  String get settingsDefaultTemplate => 'Domyślny szablon';

  @override
  String get manageTemplates => 'Zarządzaj szblonami';

  @override
  String get addTemplate => 'Dodaj szablon';

  @override
  String get newTemplate => 'Nowy szablon';

  @override
  String get noTemplateTitle => 'Brak';

  @override
  String get noTemplatesDescription => 'Brak utworzonych szablonów…';

  @override
  String get settingsStorageTitle => 'Pamięć';

  @override
  String get settingsImageQuality => 'Jakość obrazów';

  @override
  String get imageQualityHigh => 'Wysoka';

  @override
  String get imageQualityMedium => 'Średnia';

  @override
  String get imageQualityLow => 'Niska';

  @override
  String get imageQualityNoCompression => 'Brak kompresji';

  @override
  String get settingsLogFolder => 'Folder wpisów';

  @override
  String get settingsImageFolder => 'Folder obrazów';

  @override
  String get warningTitle => 'Ostrzeżenie';

  @override
  String get logFolderWarningDescription =>
      'Jeśli wybrany folder zawiera już plik \'daily_you.db\', zostanie on użyty do nadpisania twoich wpisów!';

  @override
  String get errorTitle => 'Błąd';

  @override
  String get logFolderErrorDescription =>
      'Nie udało się zmienić folderu wpisów!';

  @override
  String get imageFolderErrorDescription =>
      'Nie udało się zmienić folderu obrazów!';

  @override
  String get backupErrorDescription =>
      'Nie udało się utworzyć kopii zapasowej!';

  @override
  String get restoreErrorDescription =>
      'Nie udało się przywrócić kopii zapasowej!';

  @override
  String get settingsBackupRestoreTitle => 'Kopia i przywracanie';

  @override
  String get settingsBackup => 'Kopia zapasowa';

  @override
  String get settingsRestore => 'Przywróć';

  @override
  String get settingsRestorePromptDescription =>
      'Przywracanie kopii nadpisze wszystkie istniejące dane!';

  @override
  String tranferStatus(Object percent) {
    return 'Przenoszenie...$percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Tworzenie kopii zapasowej... $percent\$';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Przywracanie kopii zapasowej... $percent%';
  }

  @override
  String get cleanUpStatus => 'Czyszczenie…';

  @override
  String get settingsExport => 'Eksport';

  @override
  String get settingsExportToAnotherFormat => 'Eksportuj do innego formatu';

  @override
  String get settingsExportFormatDescription =>
      'To nie powinno być używane jako kopia!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importuj z innej aplikacji';

  @override
  String get settingsTranslateCallToAction =>
      'Każdy powinien mieć dostęp do dziennika!';

  @override
  String get settingsHelpTranslate => 'Pomóż w tłumaczeniu';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Wybierz format';

  @override
  String get logFormatDescription =>
      'Formaty innych aplikacji mogą nie wspierać wszystkich funkcji. Proszę o zgłaszanie jakichkolwiek błędów, ponieważ formaty tych aplikacji mogą się zmienić w każdym momencie. To nie wpłynie na istniejące wpisy!';

  @override
  String get formatDailyYouJson => 'Daily You (JSON)';

  @override
  String get formatDaylio => 'Daylio';

  @override
  String get formatDiarium => 'Diarium';

  @override
  String get formatMyBrain => 'My Brain';

  @override
  String get formatOneShot => 'OneShot';

  @override
  String get formatPixels => 'Pixels';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => 'Usuń wszystkie wpisy';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Czy chcesz usunąć wszystkie twoje wpisy?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Wprowadź \'$prompt\' by potwierdzić. Ta operacja jest nieodwracalna!';
  }

  @override
  String get settingsLanguageTitle => 'Język';

  @override
  String get settingsAppLanguageTitle => 'Język aplikacji';

  @override
  String get settingsOverrideAppLanguageTitle => 'Wymuś język aplikacji';

  @override
  String get settingsSecurityTitle => 'Bezpieczeństwo';

  @override
  String get settingsSecurityRequirePassword => 'Require Password';

  @override
  String get settingsSecurityEnterPassword => 'Wprowadź hasło';

  @override
  String get settingsSecuritySetPassword => 'Ustaw Hasło';

  @override
  String get settingsSecurityChangePassword => 'Zmień Hasło';

  @override
  String get settingsSecurityPassword => 'Hasło';

  @override
  String get settingsSecurityConfirmPassword => 'Potwierdź Hasło';

  @override
  String get settingsSecurityOldPassword => 'Stare Hasło';

  @override
  String get settingsSecurityIncorrectPassword => 'Hasło Nieprawidłowe';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Hasła się nie zgadzają';

  @override
  String get requiredPrompt => 'Required';

  @override
  String get settingsSecurityBiometricUnlock => 'Odblokowanie Biometryczne';

  @override
  String get unlockAppPrompt => 'Odblokuj aplikację';

  @override
  String get settingsAboutTitle => 'O aplikacji';

  @override
  String get settingsVersion => 'Wersja';

  @override
  String get settingsLicense => 'Licencja';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Kod źródłowy';

  @override
  String get settingsMadeWithLove => 'Zrobione z ❤️';

  @override
  String get settingsConsiderSupporting => 'rozważ wsparcie';

  @override
  String get tagMoodTitle => 'Nastrój';
}
