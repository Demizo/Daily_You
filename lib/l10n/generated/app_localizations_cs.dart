// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Zapiš si dnešek!';

  @override
  String get dailyReminderDescription => 'Zapiš si svůj den…';

  @override
  String get actionTakePhoto => 'Udělej fotku';

  @override
  String get actionToday => 'Dnes';

  @override
  String get actionOtherDay => 'Jiný den';

  @override
  String get pageHomeTitle => 'Hlavní stránka';

  @override
  String get jumpToMonthTitle => 'Jump to month';

  @override
  String get jumpToLogTitle => 'Jump to log';

  @override
  String get flashbacksTitle => 'Vzpomínky';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Vyřadit špatné dny';

  @override
  String get flaskbacksEmpty => 'Zatím žádné vzpomínky…';

  @override
  String get flashbackGoodDay => 'Dobrý den';

  @override
  String get flashbackRandomDay => 'Náhodný den';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count týdny před',
      one: '$count týden před',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count měsíců zpět',
      one: '$count měsíců zpět',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count roky zpět',
      one: '$count rok zpět',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'Tohoto dne';

  @override
  String get pageGalleryTitle => 'Galerie';

  @override
  String get searchLogsHint => 'Vyhledávání záznamů…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count záznamů',
      one: '$count záznam',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní/ů',
      one: '$count den',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    return '$count slov';
  }

  @override
  String get noLogs => 'Žádné záznamy…';

  @override
  String get noResults => 'No Results…';

  @override
  String get sortDateTitle => 'Datum';

  @override
  String get sortOrderAscendingTitle => 'Stoupající';

  @override
  String get sortOrderDescendingTitle => 'Klesající';

  @override
  String get pageStatisticsTitle => 'Statistiky';

  @override
  String get statisticsNotEnoughData => 'Nedostatek dat…';

  @override
  String get statisticsRangeOneMonth => '1 měsíc';

  @override
  String get statisticsRangeSixMonths => '6 měsíců';

  @override
  String get statisticsRangeOneYear => '1 rok';

  @override
  String get statisticsRangeAllTime => 'Celé období';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Shrnutí';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Ve dne';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag Během Času';
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
      other: 'Současný Streak $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nejdelší Streak $count',
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
      other: 'Dnů od špatného dne $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Nelze přistoupit k Externími uložišti';

  @override
  String get errorExternalStorageAccessDescription =>
      'Pokud používáte síťové úložiště, ujistěte se, že je služba online a že máte přístup k síti.\n\nV opačném případě mohla aplikace ztratit oprávnění pro externí složku. Přejděte do nastavení a znovu vyberte externí složku, abyste jí udělili přístup.\n\nUpozornění: změny nebudou synchronizovány, dokud neobnovíte přístup k externímu úložišti!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Pokračovat s lokální databází';

  @override
  String get databaseMigrationErrorTitle => 'Couldn\'t Move Your Data';

  @override
  String get databaseMigrationErrorDescription =>
      'Your entries are safe but couldn\'t be moved to the app\'s storage.\n\nTry again, and report the issue if it keeps happening.';

  @override
  String get databaseMigrationErrorRetry => 'Retry';

  @override
  String get errorReport => 'Report Issue';

  @override
  String get lastModified => 'Upraveno';

  @override
  String get writeSomethingHint => 'Napiš něco…';

  @override
  String get titleHint => 'Název…';

  @override
  String get deleteLogTitle => 'Smazat záznam';

  @override
  String get deleteLogDescription => 'Chcete smazat tento záznam?';

  @override
  String get deletePhotoTitle => 'Smazat fotografii';

  @override
  String get deletePhotoDescription => 'Chcete smazat tuto fotografii?';

  @override
  String get pageSettingsTitle => 'Nastavení';

  @override
  String get settingsAppearanceTitle => 'Vzhled';

  @override
  String get settingsTheme => 'Téma';

  @override
  String get themeSystem => 'Systém';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'První den v týdnu';

  @override
  String get settingsCalendarSystem => 'Calendar System';

  @override
  String get calendarSystemGregorian => 'Gregorian';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor => 'Použít barvu systému';

  @override
  String get settingsCustomAccentColor => 'Vlastní barva';

  @override
  String get settingsShowMarkdownToolbar => 'Zobrazit panel nástrojů';

  @override
  String get settingsShowFlashbacks => 'Zobrazit vzpomínky';

  @override
  String get settingsChangeMoodIcons => 'Změnit ikony nálad';

  @override
  String get moodIconPrompt => 'Vložte ikonu';

  @override
  String get settingsFlashbacksViewLayout => 'Zobrazení rozložení vzpomínek';

  @override
  String get settingsGalleryViewLayout => 'Rozložení zobrazení galerie';

  @override
  String get settingsHideImagesInGallery => 'Skrýt obrázky v galerii';

  @override
  String get settingsHideImages => 'Skrýt obrázky';

  @override
  String get pageCalendarTitle => 'Kalendář';

  @override
  String get viewLayoutList => 'Seznam';

  @override
  String get viewLayoutGrid => 'Mřížka';

  @override
  String get settingsNotificationsTitle => 'Oznámení';

  @override
  String get settingsDailyReminderOnboarding =>
      'Zapněte si denní připomenutí, abyste byli důslední!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'K odeslání připomenutí v náhodný okamžik nebo ve vámi preferovaný čas bude vyžadováno oprávnění „naplánovat alarmy“.';

  @override
  String get settingsDailyReminderTitle => 'Denní připomenutí';

  @override
  String get settingsOnThisDayDescription => 'Připomeňte si minulé vzpomínky';

  @override
  String get settingsDailyReminderDescription => 'Jemné každodenní připomenutí';

  @override
  String get settingsReminderTime => 'Čas připomenutí';

  @override
  String get settingsFixedReminderTimeTitle => 'Pevný čas připomenutí';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Vyberte pevný čas pro připomenutí';

  @override
  String get settingsAlwaysSendReminderTitle => 'Vždy posílat připomenutí';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Poslat připomenutí i když už byl vytvořený zápis';

  @override
  String get settingsCustomizeNotificationTitle => 'Přizpůsobit oznámení';

  @override
  String get settingsTemplatesTitle => 'Šablony';

  @override
  String get settingsDefaultTemplate => 'Výchozí šablona';

  @override
  String get manageTemplates => 'Spravovat šablony';

  @override
  String get addTemplate => 'Přidat šablonu';

  @override
  String get newTemplate => 'Nová šablona';

  @override
  String get noTemplateTitle => 'Žádná';

  @override
  String get noTemplatesDescription => 'Zatím nebyly vytvořeny žádné šablony…';

  @override
  String get templateVariableTime => 'Čas';

  @override
  String get templateDefaultTimestampTitle => 'Časový údaj';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Shrnutí dne';

  @override
  String get templateDefaultSummaryBody => '### Shrnutí\n- \n\n### Citace\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Ohlédnutí za dnem';

  @override
  String get templateDefaultReflectionBody =>
      '### Co jsem si dnes užil?\n- \n\n### Za co jsem rád?\n- \n\n### Na co se těším?\n- ';

  @override
  String get settingsTagsTitle => 'Tags';

  @override
  String get manageTags => 'Manage Tags';

  @override
  String get tagTypeLabelTitle => 'Label';

  @override
  String get tagTypeTrackerTitle => 'Tracker';

  @override
  String get nameHint => 'Name';

  @override
  String get tagColorLabel => 'Color';

  @override
  String get iconPickerTitle => 'Choose Icon';

  @override
  String get iconPickerIconsTab => 'Icons';

  @override
  String get iconPickerCustomTab => 'Custom';

  @override
  String get iconPickerSearchHint => 'Search icons…';

  @override
  String get colorPickerTitle => 'Choose Color';

  @override
  String get colorPickerPaletteTab => 'Colors';

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
  String get iconGroupHome => 'Home';

  @override
  String get iconGroupTravel => 'Travel';

  @override
  String get iconGroupSymbols => 'Symbols';

  @override
  String get tagCategoryLabel => 'Category';

  @override
  String get tagLabel => 'Tag';

  @override
  String get tagCategoryUncategorized => 'Uncategorized';

  @override
  String get newCategoryTitle => 'New Category';

  @override
  String get shareButtonLabel => 'Share';

  @override
  String get importErrorDescription => 'Failed to import file!';

  @override
  String get exportErrorDescription => 'Failed to export file!';

  @override
  String get deleteTitle => 'Delete';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' It is used in $count logs.',
      one: ' It is used in 1 log.',
      zero: '',
    );
    return 'Delete \"$name\"?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Its $count tags will also be deleted.',
      one: ' Its 1 tag will also be deleted.',
      zero: '',
    );
    return 'Delete \"$name\"?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Delete \"$name\"?';
  }

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
  String get addTagsTitle => 'Add Tags';

  @override
  String get addTagsSearchHint => 'Search tags…';

  @override
  String get tagPickerSortManualLabel => 'Manual order';

  @override
  String get tagPickerSortUsageLabel => 'Sort by usage';

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
  String get welcomeLogBodyText =>
      '## Welcome to Daily You\n\n> Every day is worth remembering, capture it!\n\n**Daily You** is free, [open source](https://github.com/Demizo/Daily_You), and community supported. Built around the belief that your diary should be yours, not a product:\n\n- No ads\n- No locked features\n- No tracking or data collection\n\nWhether you\'re journaling, reflecting, or just noting what made you smile, **Daily You** gives you a private space that\'s _truly your own_.';

  @override
  String get settingsStorageTitle => 'Uložiště';

  @override
  String get settingsImageQuality => 'Kvalita fotografie';

  @override
  String get imageQualityHigh => 'Vysoká';

  @override
  String get imageQualityMedium => 'Střední';

  @override
  String get imageQualityLow => 'Nízká';

  @override
  String get imageQualityNoCompression => 'Bez komprese';

  @override
  String get settingsLogFolder => 'Složka záznamů';

  @override
  String get settingsImageFolder => 'Složka obrázků';

  @override
  String get warningTitle => 'Varování';

  @override
  String get logFolderWarningDescription =>
      'Pokud vybraná složka již obsahuje soubor „daily_you.db“, bude použit k přepsání vašich stávajících záznamů!';

  @override
  String get errorTitle => 'Chyba';

  @override
  String get logFolderErrorDescription =>
      'Nepodařilo se změnit složku záznamů!';

  @override
  String get imageFolderErrorDescription =>
      'Nepodařilo se změnit složku obrázků!';

  @override
  String get backupErrorDescription => 'Nepodařilo se vytvořit zálohu!';

  @override
  String get restoreErrorDescription => 'Obnovení zálohy se nezdařilo!';

  @override
  String get settingsBackupRestoreTitle => 'Zálohování a obnovení';

  @override
  String get settingsBackup => 'Zálohovat';

  @override
  String get settingsRestore => 'Obnovit';

  @override
  String get settingsRestorePromptDescription =>
      'Obnovení zálohy přepíše vaše stávající data!';

  @override
  String tranferStatus(Object percent) {
    return 'Přenos… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Vytváření zálohy... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Obnovení zálohy… $percent%';
  }

  @override
  String get cleanUpStatus => 'Uklízení…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Exportovat do jiného formátu';

  @override
  String get settingsExportFormatDescription =>
      'To by nemělo být použito jako záloha!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importovat z jiné aplikace';

  @override
  String get settingsTranslateCallToAction =>
      'Každý by měl mít přístup k deníku!';

  @override
  String get settingsHelpTranslate => 'Pomozte s překladem';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Zvolte formát';

  @override
  String get logFormatDescription =>
      'Formát jiné aplikace nemusí podporovat všechny funkce. Nahlaste prosím jakékoli problémy, protože formáty třetích stran se mohou kdykoli změnit. To nebude mít vliv na stávající záznamy!';

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
  String get settingsDeleteAllLogsTitle => 'Smazat všechny záznamy';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Chcete smazat všechny své záznamy?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Zadejte \'$prompt\' pro potvrzení. Tento úkon nelze vrátit zpět!';
  }

  @override
  String get settingsLanguageTitle => 'Jazyk';

  @override
  String get settingsAppLanguageTitle => 'Jazyk aplikace';

  @override
  String get settingsOverrideAppLanguageTitle => 'Přepsat jazyk aplikace';

  @override
  String get settingsSecurityTitle => 'Zabezpečení';

  @override
  String get settingsSecurityRequirePassword => 'Vyžadovat heslo';

  @override
  String get settingsSecurityEnterPassword => 'Zadejte heslo';

  @override
  String get settingsSecuritySetPassword => 'Nastavit heslo';

  @override
  String get settingsSecurityChangePassword => 'Změnit heslo';

  @override
  String get settingsSecurityPassword => 'Heslo';

  @override
  String get settingsSecurityConfirmPassword => 'Potvrďte heslo';

  @override
  String get settingsSecurityOldPassword => 'Staré heslo';

  @override
  String get settingsSecurityIncorrectPassword => 'Nesprávné heslo';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Hesla se neshodují';

  @override
  String get requiredPrompt => 'Povinné';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometrické odemykání';

  @override
  String get unlockAppPrompt => 'Odemknout aplikaci';

  @override
  String get settingsAboutTitle => 'O nás';

  @override
  String get settingsVersion => 'Verze';

  @override
  String get settingsLicense => 'Licence';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Zdrojový kód';

  @override
  String get settingsMadeWithLove => 'Vyrobeno s ❤️';

  @override
  String get settingsConsiderSupporting => 'zvažte podporu';

  @override
  String get imagesTitle => 'Images';

  @override
  String get tagMoodTitle => 'Nálada';

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
