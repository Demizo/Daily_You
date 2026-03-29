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
  String get pageHomeTitle => 'Etusivu';

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
  String get tagMoodTitle => 'Mieliala';
}
