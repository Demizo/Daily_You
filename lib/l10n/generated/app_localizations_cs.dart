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
  String get jumpToMonthTitle => 'Skočit na měsíc';

  @override
  String get jumpToLogTitle => 'Skočit na záznam';

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
  String get noResults => 'Žádné výsledky…';

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
  String get chartGroupingLabel => 'Seskupit podle';

  @override
  String get chartGroupingDay => 'Dne';

  @override
  String get chartGroupingWeek => 'Týdne';

  @override
  String get chartGroupingMonth => 'Měsíce';

  @override
  String get chartGroupingYear => 'Roku';

  @override
  String get chartSmoothingLabel => 'Zahlazování';

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
      other: 'Dobrých dnů $count',
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
  String get databaseMigrationErrorTitle => 'Nepodařilo se přesunout vaše data';

  @override
  String get databaseMigrationErrorDescription =>
      'Vaše záznamy jsou v bezpečí, ale nepodařilo se je přesunout do úložiště aplikace.\n\nZkuste to znovu, v případě opakovaného problému nahlašte chybu.';

  @override
  String get databaseMigrationErrorRetry => 'Zkusit znovu';

  @override
  String get errorReport => 'Nahlásit chybu';

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
  String get settingsCalendarSystem => 'Kalendářní systém';

  @override
  String get calendarSystemGregorian => 'Gregoriánský';

  @override
  String get calendarSystemJalali => 'Solární kalendář Hidžry';

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
  String get settingsTagsTitle => 'Štítky';

  @override
  String get manageTags => 'Spravovat štítky';

  @override
  String get tagTypeLabelTitle => 'Značka';

  @override
  String get tagTypeTrackerTitle => 'Počítadlo';

  @override
  String get nameHint => 'Název';

  @override
  String get tagColorLabel => 'Barva';

  @override
  String get iconPickerTitle => 'Vyberte ikonu';

  @override
  String get iconPickerIconsTab => 'Ikony';

  @override
  String get iconPickerCustomTab => 'Vlastní';

  @override
  String get iconPickerSearchHint => 'Vyhledat ikony…';

  @override
  String get colorPickerTitle => 'Vyberte barvu';

  @override
  String get colorPickerPaletteTab => 'Barvy';

  @override
  String get iconGroupMoodPeople => 'Pocity a lidé';

  @override
  String get iconGroupHealth => 'Zdraví';

  @override
  String get iconGroupWorkFinance => 'Práce a peníze';

  @override
  String get iconGroupHabitsGoals => 'Zvyky a cíle';

  @override
  String get iconGroupNature => 'Příroda';

  @override
  String get iconGroupFoodDrink => 'Jídlo a pití';

  @override
  String get iconGroupHome => 'Dům';

  @override
  String get iconGroupTravel => 'Cestování';

  @override
  String get iconGroupSymbols => 'Symboly';

  @override
  String get tagCategoryLabel => 'Kategorie';

  @override
  String get tagLabel => 'Štítek';

  @override
  String get tagCategoryUncategorized => 'Nekategorizované';

  @override
  String get newCategoryTitle => 'Nová kategorie';

  @override
  String get shareButtonLabel => 'Sdílet';

  @override
  String get importErrorDescription => 'Nepodařilo se importovat soubor!';

  @override
  String get exportErrorDescription => 'Nepodařilo se exportovat soubor!';

  @override
  String get deleteTitle => 'Smazat';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Využívá se to v $count záznamech.',
      few: ' Využívá se to ve $count záznamech.',
      one: ' Využívá se to v 1 záznamu.',
      zero: '',
    );
    return 'Smazat \"$name\"?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' $count tagů budou smazaný. ',
      few: ' $count tagy budou smazaný. ',
      one: ' 1 tag bude smazaný. ',
      zero: '',
    );
    return 'Smazat \"$name\"?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Smazat „$name“?';
  }

  @override
  String get filterTagsTitle => 'Filtr';

  @override
  String get tagFilterModeAny => 'Jakýkoliv štítek';

  @override
  String get tagFilterModeAll => 'Všechny štítky';

  @override
  String get clearAllFilters => 'Smazat vše';

  @override
  String get noTagsFilterLabel => 'Žádné štítky';

  @override
  String get addTagsTitle => 'Přidat štítky';

  @override
  String get addTagsSearchHint => 'Hledat štítky…';

  @override
  String get tagPickerSortManualLabel => 'Manuální řazení';

  @override
  String get tagPickerSortUsageLabel => 'Řadit podle využití';

  @override
  String get tagFavoriteName => 'Oblíbené';

  @override
  String get tagEnergyName => 'Energie';

  @override
  String get tagCategoryActivitiesName => 'Aktivity';

  @override
  String get tagExerciseName => 'Pohyb';

  @override
  String get tagSocializingName => 'Socializace';

  @override
  String get tagHobbyName => 'Koníček';

  @override
  String get tagEntertainmentName => 'Zábava';

  @override
  String get tagDiningName => 'Jezení';

  @override
  String get tagChoresName => 'Povinnosti';

  @override
  String get tagCategoryEmotionsName => 'Emoce';

  @override
  String get tagExcitedName => 'Nadšený';

  @override
  String get tagGratefulName => 'Vděčný';

  @override
  String get tagCalmName => 'Klidný';

  @override
  String get tagTiredName => 'Unavený';

  @override
  String get tagAnxiousName => 'Úzkostlivý';

  @override
  String get tagAnnoyedName => 'Naštvaný';

  @override
  String get welcomeLogBodyText =>
      '## Vítejte v Daily You\n\n> Každý den si má cenu pamatovat, zapište si jej!\n\n**Daily You** je zdarma, [open source](https://github.com/Demizo/Daily_You), a podporovaný komunitou. Založenona myšlence, že deník by měl být soukromí a ne produkt:\n\n- Bez reklam\n- Žádný paywall\n- Žádné sledování a sběr dat\n\nAťuz si zapisujete každý den, vaše nápady, nebo co vás třeba rozesmálo, **Daily You** vám dává soukromí prostor, který _plně vlastníte_.';

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
  String get settingsBackupPasswordProtect => 'Password Protect Backups';

  @override
  String get backupEncryptedTitle => 'Encrypted Backup';

  @override
  String get backupEncryptedContent => 'This backup is password protected.';

  @override
  String get settingsAutoBackup => 'Automatic Backups';

  @override
  String get settingsAutoBackupLocation => 'Backup Location';

  @override
  String get settingsAutoBackupTime => 'Backup Time';

  @override
  String get settingsAutoBackupInterval => 'Backup Interval';

  @override
  String get settingsAutoBackupIntervalDaily => 'Daily';

  @override
  String get settingsAutoBackupIntervalWeekly => 'Weekly';

  @override
  String get settingsAutoBackupIntervalMonthly => 'Monthly';

  @override
  String get settingsAutoBackupMaxCount => 'Backups To Keep';

  @override
  String settingsBackupLast(Object time) {
    return 'Last backup $time';
  }

  @override
  String get settingsBackupNever => 'Never backed up';

  @override
  String settingsAutoBackupNext(Object time) {
    return 'Next backup $time';
  }

  @override
  String get settingsAutoBackupKeepAll => 'All';

  @override
  String get settingsAutoBackupLocationNotSet => 'Not configured';

  @override
  String get autoBackupProgressTitle => 'Backing Up…';

  @override
  String get autoBackupFailedTitle => 'Backup Failed';

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
    return 'Migruju fotky… $current/$total';
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
  String get imagesTitle => 'Obrázky';

  @override
  String get tagMoodTitle => 'Nálada';

  @override
  String get calendarTagDisplayLabel => 'Štítek';

  @override
  String get selectTagTitle => 'Vybrat štítek';

  @override
  String get labelPresentLabel => 'Přítomný';

  @override
  String get labelAbsentLabel => 'Nepřítomný';

  @override
  String get labelCoverageLabel => 'Pokrytí';

  @override
  String chartDistributionTitle(Object tag) {
    return 'Distribuce $tag';
  }
}
