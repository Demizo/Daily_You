// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Parašykite šiandien įrašą!';

  @override
  String get dailyReminderDescription => 'Parašykite kasdienį žurnalo įrašą…';

  @override
  String get actionTakePhoto => 'Fotografuoti';

  @override
  String get actionToday => 'Šiandien';

  @override
  String get actionOtherDay => 'Kita diena';

  @override
  String get pageHomeTitle => 'Pradžia';

  @override
  String get flashbacksTitle => 'Žvilgsniai į praeitį';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Neįtraukti blogų dienų';

  @override
  String get flaskbacksEmpty => 'Kol kas nėra žvilgsnių į praeitį…';

  @override
  String get flashbackGoodDay => 'Gera diena';

  @override
  String get flashbackRandomDay => 'Atsitiktinė diena';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prieš $count savaitę',
      many: 'prieš $count savaičių',
      few: 'prieš $count savaites',
      one: 'prieš $count savaitę',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prieš $count mėnesį',
      many: 'prieš $count mėnesių',
      few: 'prieš $count mėnesius',
      one: 'prieš $count mėnesį',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prieš $count metus',
      many: 'prieš $count metų',
      few: 'prieš $count metus',
      one: 'prieš $count metus',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'Šią dieną';

  @override
  String get pageGalleryTitle => 'Galerija';

  @override
  String get searchLogsHint => 'Ieškoti žurnalo įrašų…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count žurnalo įrašas',
      many: '$count žurnalo įrašų',
      few: '$count žurnalo įrašai',
      one: '$count žurnalo įrašas',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diena',
      many: '$count dienų',
      few: '$count dienos',
      one: '$count diena',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count žodis',
      many: '$count žodžių',
      few: '$count žodžiai',
      one: '$count žodis',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Nėra žurnalo įrašų…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Didėjančiai';

  @override
  String get sortOrderDescendingTitle => 'Mažėjančiai';

  @override
  String get pageStatisticsTitle => 'Statistika';

  @override
  String get statisticsNotEnoughData => 'Nepakanka duomenų…';

  @override
  String get statisticsRangeOneMonth => '1 mėnesis';

  @override
  String get statisticsRangeSixMonths => '6 mėnesiai';

  @override
  String get statisticsRangeOneYear => '1 metai';

  @override
  String get statisticsRangeAllTime => 'Visas laikas';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag santrauka';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag pagal dieną';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag bėgant laikui';
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
      other: 'Dabartinė seka $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ilgiausia seka $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Praėjo dienų nuo paskutinės blogos dienos: $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Nepavyksta pasiekti išorinės saugyklos';

  @override
  String get errorExternalStorageAccessDescription =>
      'Jei naudojate saugyklą tinkle, įsitikinkite, kad paslauga veikia ir turite prieigą prie tinklo.\n\nPriešingu atveju, gali būti, jog programėlė prarado prieigą prie išorinio aplanko. Eikite į nustatymus ir iš naujo pasirinkite išorinį aplanką, kad suteiktumėte prieigą.\n\nĮspėjimas: pakeitimai nebus sinchronizuojami tol, kol neatkursite prieigos prie išorinės saugyklos vietos!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Tęsti naudojant vietinę duomenų bazę';

  @override
  String get lastModified => 'Modifikuotas';

  @override
  String get writeSomethingHint => 'Parašykite ką nors…';

  @override
  String get titleHint => 'Pavadinimas…';

  @override
  String get deleteLogTitle => 'Ištrinti žurnalo įrašą';

  @override
  String get deleteLogDescription => 'Ar norite ištrinti šį žurnalo įrašą?';

  @override
  String get deletePhotoTitle => 'Ištrinti nuotrauką';

  @override
  String get deletePhotoDescription => 'Ar norite ištrinti šią nuotrauką?';

  @override
  String get pageSettingsTitle => 'Nustatymai';

  @override
  String get settingsAppearanceTitle => 'Išvaizda';

  @override
  String get settingsTheme => 'Apipavidalinimas';

  @override
  String get themeSystem => 'Sisteminis';

  @override
  String get themeLight => 'Šviesus';

  @override
  String get themeDark => 'Tamsus';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Pirmoji savaitės diena';

  @override
  String get settingsCalendarSystem => 'Kalendoriaus sistema';

  @override
  String get calendarSystemGregorian => 'Grigaliaus';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor =>
      'Naudoti sisteminę paryškinimo spalvą';

  @override
  String get settingsCustomAccentColor => 'Tinkinta paryškinimo spalva';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Rodyti žvilgsnius į praeitį';

  @override
  String get settingsChangeMoodIcons => 'Keisti nuotaikos piktogramas';

  @override
  String get moodIconPrompt => 'Įveskite piktogramą (jaustuką)';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Galerijos rodinio išdėstymas';

  @override
  String get settingsHideImagesInGallery => 'Slėpti paveikslus galerijoje';

  @override
  String get settingsHideImages => 'Slėpti paveikslus';

  @override
  String get pageCalendarTitle => 'Kalendorius';

  @override
  String get viewLayoutList => 'Sąrašas';

  @override
  String get viewLayoutGrid => 'Tinklelis';

  @override
  String get settingsNotificationsTitle => 'Pranešimai';

  @override
  String get settingsDailyReminderOnboarding =>
      'Įjunkite kasdienius priminimus, kad būtumėte nuoseklūs!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Bus paprašyta leidimo „Planuoti žadintuvus“, kad jūsų pageidaujamu laiku atsitiktinę akimirką būtų parodytas priminimas.';

  @override
  String get settingsDailyReminderTitle => 'Kasdienis priminimas';

  @override
  String get settingsOnThisDayDescription =>
      'Iš naujo peržiūrėti praeities prisiminimus';

  @override
  String get settingsDailyReminderDescription =>
      'Švelnus priminimas kiekvieną dieną';

  @override
  String get settingsReminderTime => 'Priminimo laikas';

  @override
  String get settingsFixedReminderTimeTitle => 'Fiksuotas priminimo laikas';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Pasirinkti konkretų priminimo laiką';

  @override
  String get settingsAlwaysSendReminderTitle => 'Visada rodyti priminimą';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Rodyti priminimą netgi tuo atveju, kai žurnalo įrašas jau pradėtas';

  @override
  String get settingsCustomizeNotificationTitle => 'Tinkinti pranešimus';

  @override
  String get settingsTemplatesTitle => 'Šablonai';

  @override
  String get settingsDefaultTemplate => 'Numatytasis šablonas';

  @override
  String get manageTemplates => 'Tvarkyti šablonus';

  @override
  String get addTemplate => 'Pridėti šabloną';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'Nėra';

  @override
  String get noTemplatesDescription => 'Kol kas nėra sukurtų šablonų…';

  @override
  String get templateVariableTime => 'Laikas';

  @override
  String get templateDefaultTimestampTitle => 'Laiko žyma';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Dienos santrauka';

  @override
  String get templateDefaultSummaryBody =>
      '### Santrauka\n- \n\n### Citata\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Apmąstymas';

  @override
  String get templateDefaultReflectionBody =>
      '### Kas jums šiandien patiko?\n- \n\n### Už ką esate dėkingi?\n- \n\n### Ko laukiate ar tikitės?\n- ';

  @override
  String get settingsStorageTitle => 'Saugykla';

  @override
  String get settingsImageQuality => 'Paveikslų kokybė';

  @override
  String get imageQualityHigh => 'Aukšta';

  @override
  String get imageQualityMedium => 'Vidutinė';

  @override
  String get imageQualityLow => 'Žema';

  @override
  String get imageQualityNoCompression => 'Be glaudinimo';

  @override
  String get settingsLogFolder => 'Žurnalo įrašų aplankas';

  @override
  String get settingsImageFolder => 'Paveikslų aplankas';

  @override
  String get warningTitle => 'Įspėjimas';

  @override
  String get logFolderWarningDescription =>
      'Jei pasirinktame aplanke jau yra \'daily_you.db\' failas, tada jis bus naudojamas perrašyti jūsų esamus žurnalo įrašus!';

  @override
  String get errorTitle => 'Klaida';

  @override
  String get logFolderErrorDescription =>
      'Nepavyko pakeisti žurnalo įrašų aplanko!';

  @override
  String get imageFolderErrorDescription =>
      'Nepavyko pakeisti paveikslų aplanko!';

  @override
  String get backupErrorDescription => 'Nepavyko sukurti atsarginės kopijos!';

  @override
  String get restoreErrorDescription => 'Nepavyko atkurti atsarginę kopiją!';

  @override
  String get settingsBackupRestoreTitle => 'Atsarginė kopija ir atkūrimas';

  @override
  String get settingsBackup => 'Daryti atsarginę kopiją';

  @override
  String get settingsRestore => 'Atkurti';

  @override
  String get settingsRestorePromptDescription =>
      'Atsarginės kopijos atkūrimas perrašys visus jūsų esamus duomenis!';

  @override
  String tranferStatus(Object percent) {
    return 'Perkeliama… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Kuriama atsarginė kopija… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Atkuriama atsarginė kopija… $percent%';
  }

  @override
  String get cleanUpStatus => 'Tvarkomasi…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Eksportuoti kitu formatu';

  @override
  String get settingsExportFormatDescription =>
      'Tai neturėtų būti naudojama kaip atsarginės kopijos kūrimui!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importuoti iš kitos programėlės';

  @override
  String get settingsTranslateCallToAction =>
      'Visiems reikia turėti prieigą prie žurnalo!';

  @override
  String get settingsHelpTranslate => 'Padėti versti';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Pasirinkti formatą';

  @override
  String get logFormatDescription =>
      'Kitos programėlės formatas gali nepalaikyti visų ypatybių. Praneškite apie bet kokias problemas, nes trečiųjų šalių formatai gali bet kuriuo metu pasikeisti. Tai neturės įtakos esamiems žurnalo įrašams!';

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
  String get settingsDeleteAllLogsTitle => 'Ištrinti visus žurnalo įrašus';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Ar norite ištrinti visus žurnalo įrašus?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Norėdami patvirtinti įrašykite \'$prompt\'. Šio veiksmo nebegalėsite atšaukti!';
  }

  @override
  String get settingsLanguageTitle => 'Kalba';

  @override
  String get settingsAppLanguageTitle => 'Programėlės kalba';

  @override
  String get settingsOverrideAppLanguageTitle => 'Nustelbti programėlės kalbą';

  @override
  String get settingsSecurityTitle => 'Saugumas';

  @override
  String get settingsSecurityRequirePassword => 'Reikalauti slaptažodžio';

  @override
  String get settingsSecurityEnterPassword => 'Įveskite slaptažodį';

  @override
  String get settingsSecuritySetPassword => 'Nustatyti slaptažodį';

  @override
  String get settingsSecurityChangePassword => 'Keisti slaptažodį';

  @override
  String get settingsSecurityPassword => 'Slaptažodis';

  @override
  String get settingsSecurityConfirmPassword => 'Pakartokite slaptažodį';

  @override
  String get settingsSecurityOldPassword => 'Senas slaptažodis';

  @override
  String get settingsSecurityIncorrectPassword => 'Neteisingas slaptažodis';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Slaptažodžiai nesutampa';

  @override
  String get requiredPrompt => 'Būtinas';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometrinis atrakinimas';

  @override
  String get unlockAppPrompt => 'Atrakinkite programėlę';

  @override
  String get settingsAboutTitle => 'Apie';

  @override
  String get settingsVersion => 'Versija';

  @override
  String get settingsLicense => 'Licencija';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Pradinis kodas';

  @override
  String get settingsMadeWithLove => 'Sukurta su ❤️';

  @override
  String get settingsConsiderSupporting => 'apsvarstykite galimybę paremti';

  @override
  String get imagesTitle => 'Images';

  @override
  String get tagMoodTitle => 'Nuotaika';
}
