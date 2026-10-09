// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Registreu el vostre dia!';

  @override
  String get dailyReminderDescription => 'Feu el vostre registre diari…';

  @override
  String get actionTakePhoto => 'Fes una foto';

  @override
  String get actionToday => 'Avui';

  @override
  String get actionOtherDay => 'Un altre dia';

  @override
  String get pageHomeTitle => 'Inici';

  @override
  String get jumpToMonthTitle => 'Salta al mes';

  @override
  String get jumpToLogTitle => 'Salta al registre';

  @override
  String get flashbacksTitle => 'Records';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclou els dies dolents';

  @override
  String get flaskbacksEmpty => 'Encara no hi ha records…';

  @override
  String get flashbackGoodDay => 'Un bon dia';

  @override
  String get flashbackRandomDay => 'Un dia a l\'atzar';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fa $count setmanes',
      one: 'Fa $count setmana',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fa $count mesos',
      one: 'Fa $count mes',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fa $count anys',
      one: 'Fa $count any',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'Un dia com avui';

  @override
  String get pageGalleryTitle => 'Galeria';

  @override
  String get searchLogsHint => 'Cerca registres…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registres',
      one: '$count registre',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '$count dia',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots',
      one: '$count mot',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Sense registres…';

  @override
  String get noResults => 'Sense resultats…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Ascendent';

  @override
  String get sortOrderDescendingTitle => 'Descendent';

  @override
  String get pageStatisticsTitle => 'Estadístiques';

  @override
  String get statisticsNotEnoughData => 'No hi ha prou dades…';

  @override
  String get statisticsRangeOneMonth => '1 mes';

  @override
  String get statisticsRangeSixMonths => '6 mesos';

  @override
  String get statisticsRangeOneYear => '1 any';

  @override
  String get statisticsRangeAllTime => 'Tot el temps';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Resum de $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag per dia';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag al llarg del temps';
  }

  @override
  String get chartGroupingLabel => 'Agrupa per';

  @override
  String get chartGroupingDay => 'Dia';

  @override
  String get chartGroupingWeek => 'Setmana';

  @override
  String get chartGroupingMonth => 'Mes';

  @override
  String get chartGroupingYear => 'Any';

  @override
  String get chartSmoothingLabel => 'Suavitzat';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ratxa actual: $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ratxa més llarga: $count',
    );
    return '$_temp0';
  }

  @override
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dies excel·lents: $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dies des d\'un dia dolent: $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'No es pot accedir a l\'emmagatzematge extern';

  @override
  String get errorExternalStorageAccessDescription =>
      'Si utilitzeu emmagatzematge de xarxa, assegureu-vos que el servei estigui en línia i que tingueu accés a la xarxa.\n\nSi no és el cas, és possible que l\'aplicació hagi perdut els permisos de la carpeta externa. Aneu als paràmetres i torneu a seleccionar la carpeta externa per a concedir-hi accés.\n\nAdvertiment: els canvis no se sincronitzaran fins que restaureu l\'accés a la ubicació d\'emmagatzematge externa.';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continua amb la base de dades local';

  @override
  String get databaseMigrationErrorTitle =>
      'No s\'han pogut moure les vostres dades';

  @override
  String get databaseMigrationErrorDescription =>
      'Les vostres entrades estan segures, però no s\'han pogut moure a l\'emmagatzematge de l\'aplicació.\n\nTorneu-ho a provar i informeu del problema si continua passant.';

  @override
  String get databaseMigrationErrorRetry => 'Torna-ho a provar';

  @override
  String get errorReport => 'Informa d\'un problema';

  @override
  String get lastModified => 'Modificat';

  @override
  String get writeSomethingHint => 'Escriviu alguna cosa…';

  @override
  String get titleHint => 'Títol…';

  @override
  String get deleteLogTitle => 'Suprimeix el registre';

  @override
  String get deleteLogDescription => 'Voleu suprimir aquest registre?';

  @override
  String get deletePhotoTitle => 'Suprimeix la foto';

  @override
  String get deletePhotoDescription => 'Voleu suprimir aquesta foto?';

  @override
  String get pageSettingsTitle => 'Paràmetres';

  @override
  String get settingsAppearanceTitle => 'Aparença';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Clar';

  @override
  String get themeDark => 'Fosc';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Primer dia de la setmana';

  @override
  String get settingsCalendarSystem => 'Sistema de calendari';

  @override
  String get calendarSystemGregorian => 'Gregorià';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor =>
      'Usa el color d\'accent del sistema';

  @override
  String get settingsCustomAccentColor => 'Color d\'accent personalitzat';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Mostra els records';

  @override
  String get settingsChangeMoodIcons => 'Canvia les icones de l\'estat d\'ànim';

  @override
  String get moodIconPrompt => 'Introdueix una icona';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout =>
      'Disposició de la vista de la galeria';

  @override
  String get settingsHideImagesInGallery => 'Amaga les imatges a la galeria';

  @override
  String get settingsHideImages => 'Amaga les imatges';

  @override
  String get pageCalendarTitle => 'Calendari';

  @override
  String get viewLayoutList => 'Llista';

  @override
  String get viewLayoutGrid => 'Graella';

  @override
  String get settingsNotificationsTitle => 'Notificacions';

  @override
  String get settingsDailyReminderOnboarding =>
      'Activeu els recordatoris diaris per a mantenir la constància.';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Se sol·licitarà el permís «programa alarmes» per a enviar el recordatori en un moment aleatori o a l\'hora que preferiu.';

  @override
  String get settingsDailyReminderTitle => 'Recordatori diari';

  @override
  String get settingsOnThisDayDescription => 'Revisita records del passat';

  @override
  String get settingsDailyReminderDescription => 'Un recordatori suau cada dia';

  @override
  String get settingsReminderTime => 'Hora del recordatori';

  @override
  String get settingsFixedReminderTimeTitle => 'Hora fixa del recordatori';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Trieu una hora fixa per al recordatori';

  @override
  String get settingsAlwaysSendReminderTitle => 'Envia sempre el recordatori';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Envia el recordatori encara que ja s\'hagi començat un registre';

  @override
  String get settingsCustomizeNotificationTitle =>
      'Personalitza les notificacions';

  @override
  String get settingsTemplatesTitle => 'Plantilles';

  @override
  String get settingsDefaultTemplate => 'Plantilla predeterminada';

  @override
  String get manageTemplates => 'Gestiona les plantilles';

  @override
  String get addTemplate => 'Afegeix una plantilla';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'Cap';

  @override
  String get noTemplatesDescription => 'Encara no s\'ha creat cap plantilla…';

  @override
  String get templateVariableTime => 'Hora';

  @override
  String get templateDefaultTimestampTitle => 'Marca horària';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Resum del dia';

  @override
  String get templateDefaultSummaryBody => '### Resum\n- \n\n### Cita\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Reflexió';

  @override
  String get templateDefaultReflectionBody =>
      '### Què us ha agradat d\'avui?\n- \n\n### Què agraïu?\n- \n\n### Què espereu amb ganes?\n- ';

  @override
  String get settingsTagsTitle => 'Etiquetes';

  @override
  String get manageTags => 'Gestiona les etiquetes';

  @override
  String get tagTypeLabelTitle => 'Etiqueta';

  @override
  String get tagTypeTrackerTitle => 'Seguiment';

  @override
  String get nameHint => 'Nom';

  @override
  String get tagColorLabel => 'Color';

  @override
  String get iconPickerTitle => 'Trieu una icona';

  @override
  String get iconPickerIconsTab => 'Icones';

  @override
  String get iconPickerCustomTab => 'Personalitzat';

  @override
  String get iconPickerSearchHint => 'Cerca icones…';

  @override
  String get colorPickerTitle => 'Trieu un color';

  @override
  String get colorPickerPaletteTab => 'Colors';

  @override
  String get iconGroupMoodPeople => 'Estat d\'ànim i persones';

  @override
  String get iconGroupHealth => 'Salut';

  @override
  String get iconGroupWorkFinance => 'Feina i finances';

  @override
  String get iconGroupHabitsGoals => 'Hàbits i objectius';

  @override
  String get iconGroupNature => 'Natura';

  @override
  String get iconGroupFoodDrink => 'Menjar i beguda';

  @override
  String get iconGroupHome => 'Llar';

  @override
  String get iconGroupTravel => 'Viatges';

  @override
  String get iconGroupSymbols => 'Símbols';

  @override
  String get tagCategoryLabel => 'Categoria';

  @override
  String get tagLabel => 'Etiqueta';

  @override
  String get tagCategoryUncategorized => 'Sense categoria';

  @override
  String get newCategoryTitle => 'Categoria nova';

  @override
  String get shareButtonLabel => 'Comparteix';

  @override
  String get importErrorDescription => 'No s\'ha pogut importar el fitxer.';

  @override
  String get exportErrorDescription => 'No s\'ha pogut exportar el fitxer.';

  @override
  String get deleteTitle => 'Suprimeix';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' S\'utilitza en $count registres.',
      one: ' S\'utilitza en un registre.',
      zero: '',
    );
    return 'Voleu suprimir «$name»?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' També se suprimiran les seves $count etiquetes.',
      one: ' També se suprimirà la seva etiqueta.',
      zero: '',
    );
    return 'Voleu suprimir «$name»?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Voleu suprimir «$name»?';
  }

  @override
  String get filterTagsTitle => 'Filtre';

  @override
  String get tagFilterModeAny => 'Qualsevol etiqueta';

  @override
  String get tagFilterModeAll => 'Totes les etiquetes';

  @override
  String get clearAllFilters => 'Neteja-ho tot';

  @override
  String get noTagsFilterLabel => 'Sense etiquetes';

  @override
  String get addTagsTitle => 'Afegeix etiquetes';

  @override
  String get addTagsSearchHint => 'Cerca etiquetes…';

  @override
  String get tagPickerSortManualLabel => 'Ordre manual';

  @override
  String get tagPickerSortUsageLabel => 'Ordena per ús';

  @override
  String get tagFavoriteName => 'Preferit';

  @override
  String get tagEnergyName => 'Energia';

  @override
  String get tagCategoryActivitiesName => 'Activitats';

  @override
  String get tagExerciseName => 'Exercici';

  @override
  String get tagSocializingName => 'Vida social';

  @override
  String get tagHobbyName => 'Afició';

  @override
  String get tagEntertainmentName => 'Entreteniment';

  @override
  String get tagDiningName => 'Menjar fora';

  @override
  String get tagChoresName => 'Feines de casa';

  @override
  String get tagCategoryEmotionsName => 'Emocions';

  @override
  String get tagExcitedName => 'Entusiasme';

  @override
  String get tagGratefulName => 'Gratitud';

  @override
  String get tagCalmName => 'Calma';

  @override
  String get tagTiredName => 'Cansament';

  @override
  String get tagAnxiousName => 'Ansietat';

  @override
  String get tagAnnoyedName => 'Enuig';

  @override
  String get welcomeLogBodyText =>
      '## Us donem la benvinguda al Daily You\n\n> Cada dia val la pena recordar-lo, captureu-lo!\n\nEl **Daily You** és gratuït, de [codi obert](https://github.com/Demizo/Daily_You), i el manté la comunitat. Es basa en la idea que el vostre diari ha de ser vós, no un producte:\n\n- Sense anuncis\n- Sense funcions bloquejades\n- Sense seguiment ni recollida de dades\n\nTant si porteu un diari, reflexioneu, com si simplement anoteu què us ha fet somriure, el **Daily You** us dona un espai privat que és _realment vostre_.';

  @override
  String get settingsStorageTitle => 'Emmagatzematge';

  @override
  String get settingsImageQuality => 'Qualitat de la imatge';

  @override
  String get imageQualityHigh => 'Alta';

  @override
  String get imageQualityMedium => 'Mitjana';

  @override
  String get imageQualityLow => 'Baixa';

  @override
  String get imageQualityNoCompression => 'Sense compressió';

  @override
  String get settingsLogFolder => 'Carpeta de registres';

  @override
  String get settingsImageFolder => 'Carpeta d\'imatges';

  @override
  String get warningTitle => 'Advertiment';

  @override
  String get logFolderWarningDescription =>
      'Si la carpeta seleccionada ja conté un fitxer «daily_you.db», s\'utilitzarà per a sobreescriure els vostres registres existents!';

  @override
  String get errorTitle => 'Error';

  @override
  String get logFolderErrorDescription =>
      'No s\'ha pogut canviar la carpeta de registres.';

  @override
  String get imageFolderErrorDescription =>
      'No s\'ha pogut canviar la carpeta d\'imatges.';

  @override
  String get backupErrorDescription =>
      'No s\'ha pogut crear la còpia de seguretat.';

  @override
  String get restoreErrorDescription =>
      'No s\'ha pogut restaurar la còpia de seguretat.';

  @override
  String get settingsBackupRestoreTitle => 'Còpia de seguretat i restauració';

  @override
  String get settingsBackup => 'Còpia de seguretat';

  @override
  String get settingsRestore => 'Restaura';

  @override
  String get settingsRestorePromptDescription =>
      'Si restaureu una còpia de seguretat, se sobreescriuran les dades existents.';

  @override
  String get settingsBackupPasswordProtect =>
      'Protegeix les còpies de seguretat amb contrasenya';

  @override
  String get backupEncryptedTitle => 'Còpia de seguretat xifrada';

  @override
  String get backupEncryptedContent =>
      'Aquesta còpia de seguretat està protegida amb contrasenya.';

  @override
  String get settingsAutoBackup => 'Còpies de seguretat automàtiques';

  @override
  String get settingsAutoBackupLocation => 'Ubicació de la còpia de seguretat';

  @override
  String get settingsAutoBackupInterval => 'Interval de còpia de seguretat';

  @override
  String get settingsAutoBackupIntervalDaily => 'Diari';

  @override
  String get settingsAutoBackupIntervalWeekly => 'Setmanal';

  @override
  String get settingsAutoBackupIntervalMonthly => 'Mensual';

  @override
  String get settingsAutoBackupMaxCount => 'Còpies de seguretat a conservar';

  @override
  String get settingsAutoBackupRequireCharging => 'Només durant la càrrega';

  @override
  String settingsBackupLast(Object time) {
    return 'Última còpia de seguretat: $time';
  }

  @override
  String get settingsBackupNever => 'Mai no s\'ha fet cap còpia de seguretat';

  @override
  String settingsAutoBackupNext(Object time) {
    return 'Pròxima còpia de seguretat: $time';
  }

  @override
  String get settingsAutoBackupKeepAll => 'Totes';

  @override
  String get autoBackupFailedTitle => 'Ha fallat la còpia de seguretat';

  @override
  String tranferStatus(Object percent) {
    return 'S\'està transferint… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'S\'està creant la còpia de seguretat… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'S\'està restaurant la còpia de seguretat… $percent%';
  }

  @override
  String encryptingBackupStatus(Object percent) {
    return 'S\'està xifrant la còpia de seguretat… $percent%';
  }

  @override
  String decryptingBackupStatus(Object percent) {
    return 'S\'està desxifrant la còpia de seguretat… $percent%';
  }

  @override
  String get cleanUpStatus => 'S\'està netejant…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'S\'estan migrant les fotos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Exporta a un altre format';

  @override
  String get settingsExportFormatDescription =>
      'No s\'ha d\'utilitzar com a còpia de seguretat!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp =>
      'Importa des d\'una altra aplicació';

  @override
  String get settingsTranslateCallToAction =>
      'Tothom hauria de tenir accés a un diari!';

  @override
  String get settingsHelpTranslate => 'Ajudeu a traduir';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Trieu un format';

  @override
  String get logFormatDescription =>
      'És possible que el format d\'una altra aplicació no admeti totes les funcions. Informeu de qualsevol problema, ja que els formats de tercers poden canviar en qualsevol moment. Això no afectarà els registres existents.';

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
  String get settingsDeleteAllLogsTitle => 'Suprimeix tots els registres';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Voleu suprimir tots els vostres registres?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Introduïu «$prompt» per a confirmar-ho. Aquesta acció no es pot desfer.';
  }

  @override
  String get settingsLanguageTitle => 'Llengua';

  @override
  String get settingsAppLanguageTitle => 'Llengua de l\'aplicació';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Substitueix la lengua de l\'aplicació';

  @override
  String get settingsSecurityTitle => 'Seguretat';

  @override
  String get settingsSecurityRequirePassword => 'Requereix contrasenya';

  @override
  String get settingsSecurityEnterPassword => 'Introduïu la contrasenya';

  @override
  String get settingsSecuritySetPassword => 'Estableix una contrasenya';

  @override
  String get settingsSecurityChangePassword => 'Canvia la contrasenya';

  @override
  String get settingsSecurityPassword => 'Contrasenya';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmeu la contrasenya';

  @override
  String get settingsSecurityOldPassword => 'Contrasenya antiga';

  @override
  String get settingsSecurityIncorrectPassword => 'Contrasenya incorrecta';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Les contrasenyes no coincideixen';

  @override
  String get requiredPrompt => 'Obligatori';

  @override
  String get settingsSecurityBiometricUnlock => 'Desblocatge biomètric';

  @override
  String get unlockAppPrompt => 'Desbloca l\'aplicació';

  @override
  String get settingsAboutTitle => 'Quant a';

  @override
  String get settingsVersion => 'Versió';

  @override
  String get settingsLicense => 'Llicència';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Codi font';

  @override
  String get settingsOpenSourceLicenses => 'Llicències de codi obert';

  @override
  String get settingsMadeWithLove => 'Fet amb ❤️';

  @override
  String get settingsConsiderSupporting => 'considereu donar-hi suport';

  @override
  String get imagesTitle => 'Imatges';

  @override
  String get tagMoodTitle => 'Estat d\'ànim';

  @override
  String get calendarTagDisplayLabel => 'Etiqueta';

  @override
  String get selectTagTitle => 'Selecciona una etiqueta';

  @override
  String get labelPresentLabel => 'Present';

  @override
  String get labelAbsentLabel => 'Absent';

  @override
  String get labelCoverageLabel => 'Cobertura';

  @override
  String chartDistributionTitle(Object tag) {
    return 'Distribució de $tag';
  }

  @override
  String get shareAddToLogPickerTitle => 'Choose a log';

  @override
  String get settingsAllowNetworkTitle => 'Allow network access';

  @override
  String get settingsAllowNetworkDescription =>
      'Enable outbound network requests for online features';

  @override
  String get developerOptionsTitle => 'Developer options';

  @override
  String get developerOptionsDescription =>
      'Diagnostic logging and developer tools';

  @override
  String get settingsDiagnosticLoggingTitle => 'Diagnostic logging';

  @override
  String get settingsDiagnosticLoggingDescription =>
      'Record internal debug logs in memory';

  @override
  String get consoleLogsTitle => 'Console logs';

  @override
  String get clearLogs => 'Clear logs';

  @override
  String get copyLogs => 'Copy logs';

  @override
  String get logsCopied => 'Logs copied to clipboard';

  @override
  String get noLogsRecorded => 'No logs recorded yet';

  @override
  String get settingsScreenProtectionTitle => 'Screen protection';

  @override
  String get settingsScreenProtectionDescription =>
      'Block screenshots and hide preview in recents';

  @override
  String get settingsEditorTitle => 'Editor';

  @override
  String get settingsMarkdownTitle => 'Markdown formatting';

  @override
  String get settingsMarkdownDescription =>
      'Render rich text and markdown formatting';

  @override
  String get settingsAutocorrectTitle => 'Autocorrect';

  @override
  String get settingsAutocorrectDescription =>
      'Enable keyboard autocorrect and spell check';

  @override
  String get settingsCapitalizationTitle => 'Auto-capitalization';

  @override
  String get settingsCapitalizationDescription =>
      'Automatically capitalize sentences';

  @override
  String get securityQuestionTitle => 'Security question';

  @override
  String get securityQuestionDescription =>
      'Recover your PIN using a security question';

  @override
  String get securityQuestionPrompt => 'Security question';

  @override
  String get securityAnswerPrompt => 'Security answer';

  @override
  String get forgotPasswordButton => 'Forgot PIN?';

  @override
  String get securityQuestionWrongAnswer => 'Incorrect answer';

  @override
  String get securityQuestionResetPrompt => 'PIN has been reset.';
}
