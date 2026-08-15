// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Täytä päiväkirja tänään!';

  @override
  String get dailyReminderDescription => 'Pidä päivittäinen päiväkirjasi…';

  @override
  String get actionTakePhoto => 'Take photo';

  @override
  String get actionToday => 'Today';

  @override
  String get actionOtherDay => 'Other day';

  @override
  String get pageHomeTitle => 'Etusivu';

  @override
  String get jumpToMonthTitle => 'Jump to month';

  @override
  String get jumpToLogTitle => 'Jump to log';

  @override
  String get flashbacksTitle => 'Muistikuvat';

  @override
  String get settingsFlashbacksExcludeBadDays =>
      'Jätä huonot päivät huomioimatta';

  @override
  String get flaskbacksEmpty => 'Ei ole vielä muistikuvia…';

  @override
  String get flashbackGoodDay => 'Hyvä päivä';

  @override
  String get flashbackRandomDay => 'Satunnainen päivä';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viikkoa sitten',
      one: '$count viikko sitten',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kuukautta sitten',
      one: '$count kuukausi sitten',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vuotta sitten',
      one: '$count vuosi sitten',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'On This Day';

  @override
  String get pageGalleryTitle => 'Galleria';

  @override
  String get searchLogsHint => 'Hae lokeista…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lokia',
      one: '$count loki',
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
      other: '$count sanaa',
      one: '$count sana',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Ei lokeja…';

  @override
  String get noResults => 'No Results…';

  @override
  String get sortDateTitle => 'Päivämäärä';

  @override
  String get sortOrderAscendingTitle => 'Nouseva';

  @override
  String get sortOrderDescendingTitle => 'Laskeva';

  @override
  String get pageStatisticsTitle => 'Tilastot';

  @override
  String get statisticsNotEnoughData => 'Ei tarpeeksi dataa…';

  @override
  String get statisticsRangeOneMonth => 'Yksi kuukausi';

  @override
  String get statisticsRangeSixMonths => 'Kuusi kuukautta';

  @override
  String get statisticsRangeOneYear => 'Yksi vuosi';

  @override
  String get statisticsRangeAllTime => 'Koko aika';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Yhteenveto';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Päiväkohtaisesti';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag Over Time';
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
      other: 'Nykyinen putki $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pisin putki $count',
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
      other: 'Päiviä huonosta päivästä lähtien $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Ulkoiseen tallennustilaan ei pääse käsiksi';

  @override
  String get errorExternalStorageAccessDescription =>
      'Jos käytät verkkotallennustilaa, varmista, että palvelu on verkossa ja sinulla on verkkoyhteys.\n\nMuuten sovellus on saattanut menettää ulkoisen kansion käyttöoikeudet. Siirry asetuksiin ja valitse ulkoinen kansio uudelleen myöntääksesi käyttöoikeudet.\n\nVaroitus: muutoksia ei synkronoida, ennen kuin palautat käyttöoikeuden ulkoiseen tallennussijaintiin!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Jatka paikallisen tietokannan kanssa';

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
  String get lastModified => 'Muokattu';

  @override
  String get writeSomethingHint => 'Kirjoita jotain…';

  @override
  String get titleHint => 'Otsikko…';

  @override
  String get deleteLogTitle => 'Poista loki';

  @override
  String get deleteLogDescription => 'Haluatko poistaa tämän lokin?';

  @override
  String get deletePhotoTitle => 'Poista valokuva';

  @override
  String get deletePhotoDescription => 'Haluatko poistaa tämän valokuvan?';

  @override
  String get pageSettingsTitle => 'Asetukset';

  @override
  String get settingsAppearanceTitle => 'Ulkoasu';

  @override
  String get settingsTheme => 'Teema';

  @override
  String get themeSystem => 'Järjestelmä';

  @override
  String get themeLight => 'Vaalea';

  @override
  String get themeDark => 'Tumma';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Viikon ensimmäinen päivä';

  @override
  String get settingsCalendarSystem => 'Calendar System';

  @override
  String get calendarSystemGregorian => 'Gregorian';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor => 'Käytä järjestelmän korostusväriä';

  @override
  String get settingsCustomAccentColor => 'Mukautettu korostusväri';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Näytä takaumat';

  @override
  String get settingsChangeMoodIcons => 'Vaihda mielialakuvakkeita';

  @override
  String get moodIconPrompt => 'Syötä kuvake';

  @override
  String get settingsFlashbacksViewLayout => 'Takaumien näkymän asettelu';

  @override
  String get settingsGalleryViewLayout => 'Gallerianäkymän asettelu';

  @override
  String get settingsHideImagesInGallery => 'Piilota kuvat galleriassa';

  @override
  String get settingsHideImages => 'Hide Images';

  @override
  String get pageCalendarTitle => 'Calendar';

  @override
  String get viewLayoutList => 'Lista';

  @override
  String get viewLayoutGrid => 'Ruudukko';

  @override
  String get settingsNotificationsTitle => 'Ilmoitukset';

  @override
  String get settingsDailyReminderOnboarding =>
      'Ota päivittäiset muistutukset käyttöön pysyäksesi johdonmukaisena!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      '\'Ajoita hälytykset\' -lupaa pyydetään muistutuksen lähettämiseksi satunnaiseen aikaan tai haluamanasi aikana.';

  @override
  String get settingsDailyReminderTitle => 'Päivittäinen muistutus';

  @override
  String get settingsOnThisDayDescription => 'Revisit past memories';

  @override
  String get settingsDailyReminderDescription => 'Lempeä muistutus joka päivä';

  @override
  String get settingsReminderTime => 'Muistutusaika';

  @override
  String get settingsFixedReminderTimeTitle => 'Kiinteä muistutusaika';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Valitse muistutukselle kiinteä aika';

  @override
  String get settingsAlwaysSendReminderTitle => 'Lähetä aina muistutus';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Lähetä muistutus, vaikka loki olisi jo aloitettu';

  @override
  String get settingsCustomizeNotificationTitle => 'Mukauta ilmoituksia';

  @override
  String get settingsTemplatesTitle => 'Pohjamallit';

  @override
  String get settingsDefaultTemplate => 'Oletuspohjamalli';

  @override
  String get manageTemplates => 'Hallitse pohjamalleja';

  @override
  String get addTemplate => 'Lisää pohjamalli';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'Ei mitään';

  @override
  String get noTemplatesDescription => 'Ei vielä luotuja pohjamalleja…';

  @override
  String get templateVariableTime => 'Aika';

  @override
  String get templateDefaultTimestampTitle => 'Aikaleima';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Päivän yhteenveto';

  @override
  String get templateDefaultSummaryBody =>
      '### Yhteenveto\n- \n\n### Lainaus\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Pohdinta';

  @override
  String get templateDefaultReflectionBody =>
      '### Mistä nautit tänään?\n- \n\n### Mistä olet kiitollinen?\n- \n\n### Mitä odotat innolla?\n- ';

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
  String get settingsStorageTitle => 'Tallennustila';

  @override
  String get settingsImageQuality => 'Kuvanlaatu';

  @override
  String get imageQualityHigh => 'Korkea';

  @override
  String get imageQualityMedium => 'Keskitasoinen';

  @override
  String get imageQualityLow => 'Alhainen';

  @override
  String get imageQualityNoCompression => 'Ei pakkausta';

  @override
  String get settingsLogFolder => 'Lokikansio';

  @override
  String get settingsImageFolder => 'Kuvakansio';

  @override
  String get warningTitle => 'Varoitus';

  @override
  String get logFolderWarningDescription =>
      'Jos valitussa kansiossa on jo \'daily_you.db\'-tiedosto, sitä käytetään olemassa olevien lokien korvaamiseen!';

  @override
  String get errorTitle => 'Virhe';

  @override
  String get logFolderErrorDescription =>
      'Lokikansion vaihtaminen epäonnistui!';

  @override
  String get imageFolderErrorDescription =>
      'Kuvakansion vaihtaminen epäonnistui!';

  @override
  String get backupErrorDescription => 'Varmuuskopion luominen epäonnistui!';

  @override
  String get restoreErrorDescription =>
      'Varmuuskopion palauttaminen epäonnistui!';

  @override
  String get settingsBackupRestoreTitle => 'Varmuuskopiointi ja palautus';

  @override
  String get settingsBackup => 'Varmuuskopioi';

  @override
  String get settingsRestore => 'Palauta';

  @override
  String get settingsRestorePromptDescription =>
      'Varmuuskopion palauttaminen korvaa olemassa olevat tiedot!';

  @override
  String tranferStatus(Object percent) {
    return 'Siirretään… $percent %';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Varmuuskopiota luodaan… $percent %';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Varmuuskopiota palautetaan… $percent %';
  }

  @override
  String get cleanUpStatus => 'Siivotaan…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Vie toiseen muotoon';

  @override
  String get settingsExportFormatDescription =>
      'Tätä ei tule käyttää varmuuskopiona!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Tuo toisesta sovelluksesta';

  @override
  String get settingsTranslateCallToAction =>
      'Jokaisella pitäisi olla pääsy päiväkirjaan!';

  @override
  String get settingsHelpTranslate => 'Auta kääntämään';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Valitse muoto';

  @override
  String get logFormatDescription =>
      'Toisen sovelluksen muoto ei välttämättä tue kaikkia ominaisuuksia. Ilmoita kaikista vioista, koska kolmansien osapuolten muodot voivat muuttua milloin tahansa. Tämä ei vaikuta olemassa oleviin lokeihin!';

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
  String get settingsDeleteAllLogsTitle => 'Poista kaikki lokit';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Haluatko poistaa kaikki lokisi?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Vahvista syöttämällä \'$prompt\'. Tätä ei voi perua!';
  }

  @override
  String get settingsLanguageTitle => 'Kieli';

  @override
  String get settingsAppLanguageTitle => 'Sovelluksen kieli';

  @override
  String get settingsOverrideAppLanguageTitle => 'Ohita sovelluksen kieli';

  @override
  String get settingsSecurityTitle => 'Turvallisuus';

  @override
  String get settingsSecurityRequirePassword => 'Vaadi salasana';

  @override
  String get settingsSecurityEnterPassword => 'Syötä salasana';

  @override
  String get settingsSecuritySetPassword => 'Aseta salasana';

  @override
  String get settingsSecurityChangePassword => 'Vaihda salasana';

  @override
  String get settingsSecurityPassword => 'Salasana';

  @override
  String get settingsSecurityConfirmPassword => 'Vahvista salasana';

  @override
  String get settingsSecurityOldPassword => 'Vanha salasana';

  @override
  String get settingsSecurityIncorrectPassword => 'Väärä salasana';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Salasanat eivät täsmää';

  @override
  String get requiredPrompt => 'Pakollinen';

  @override
  String get settingsSecurityBiometricUnlock =>
      'Biometrinen lukituksen avaaminen';

  @override
  String get unlockAppPrompt => 'Avaa sovelluksen lukitus';

  @override
  String get settingsAboutTitle => 'Tietoja';

  @override
  String get settingsVersion => 'Versio';

  @override
  String get settingsLicense => 'Lisenssi';

  @override
  String get licenseGPLv3 => 'GPL-v. 3.0';

  @override
  String get settingsSourceCode => 'Lähdekoodi';

  @override
  String get settingsMadeWithLove => '❤️:lla tehty';

  @override
  String get settingsConsiderSupporting => 'harkitse tukemista';

  @override
  String get imagesTitle => 'Images';

  @override
  String get tagMoodTitle => 'Mieliala';

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
