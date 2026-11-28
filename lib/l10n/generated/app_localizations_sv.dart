// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Dags att skriva dagbok!';

  @override
  String get dailyReminderDescription => 'Berätta om din dag…';

  @override
  String get actionTakePhoto => 'Ta ett foto';

  @override
  String get actionTakeVideo => 'Spela in video';

  @override
  String get actionRecordAudio => 'Spela in ljud';

  @override
  String get actionAddImage => 'Lägg till bild';

  @override
  String get actionAddVideo => 'Lägg till video';

  @override
  String get actionAddAudio => 'Lägg till ljud';

  @override
  String get actionToday => 'I dag';

  @override
  String get actionOtherDay => 'En annan dag';

  @override
  String get pageHomeTitle => 'Hem';

  @override
  String get jumpToMonthTitle => 'Gå till månad';

  @override
  String get jumpToLogTitle => 'Gå till anteckning';

  @override
  String get flashbacksTitle => 'Tillbakablickar';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Uteslut dåliga dagar';

  @override
  String get flaskbacksEmpty => 'Inga tillbakablickar än…';

  @override
  String get flashbackGoodDay => 'En bra dag';

  @override
  String get flashbackRandomDay => 'En slumpvald dag';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'För $count veckor sedan',
      one: 'För $count vecka sedan',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'För $count månader sedan',
      one: 'För $count månad sedan',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'För $count år sedan',
      one: 'För $count år sedan',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'Den här dagen tidigare år';

  @override
  String get pageGalleryTitle => 'Galleri';

  @override
  String get searchLogsHint => 'Sök bland anteckningarna…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anteckningar',
      one: '$count anteckning',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar',
      one: '$count dag',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ord',
      one: '$count ord',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Inga anteckningar…';

  @override
  String get noResults => 'Inga träffar…';

  @override
  String get sortDateTitle => 'Datum';

  @override
  String get sortOrderAscendingTitle => 'Stigande';

  @override
  String get sortOrderDescendingTitle => 'Fallande';

  @override
  String get pageStatisticsTitle => 'Statistik';

  @override
  String get statisticsNotEnoughData => 'För lite underlag än så länge…';

  @override
  String get statisticsRangeOneMonth => '1 månad';

  @override
  String get statisticsRangeSixMonths => '6 månader';

  @override
  String get statisticsRangeOneYear => '1 år';

  @override
  String get statisticsRangeAllTime => 'Hela perioden';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Översikt över $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag per veckodag';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag över tid';
  }

  @override
  String chartInfluencesTitle(Object tag) {
    return 'Samband med $tag';
  }

  @override
  String get chartGroupingLabel => 'Gruppera efter';

  @override
  String get chartGroupingDay => 'Dag';

  @override
  String get chartGroupingWeek => 'Vecka';

  @override
  String get chartGroupingMonth => 'Månad';

  @override
  String get chartGroupingYear => 'År';

  @override
  String get chartSmoothingLabel => 'Utjämning';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Current Streak $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Longest Streak $count',
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
      other: 'Days Since a Bad Day $count',
    );
    return '$_temp0';
  }

  @override
  String streakDayLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dagar i rad',
      one: 'dag i rad',
    );
    return '$_temp0';
  }

  @override
  String statsLogsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'anteckningar',
      one: 'anteckning',
    );
    return '$_temp0';
  }

  @override
  String statsWordsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ord',
      one: 'ord',
    );
    return '$_temp0';
  }

  @override
  String statsDaysLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dagar',
      one: 'dag',
    );
    return '$_temp0';
  }

  @override
  String get statsLongestStreakTitle => 'Längsta svit';

  @override
  String get statsWritingTitle => 'Skrivande';

  @override
  String get statsWordsPerLogTitle => 'Ord per anteckning';

  @override
  String get statsLongestLogTitle => 'Längsta anteckningen';

  @override
  String statsMostActiveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Veckodagar med flest anteckningar',
      one: 'Veckodag med flest anteckningar',
    );
    return '$_temp0';
  }

  @override
  String statsDaysOfRange(int written, int total) {
    final intl.NumberFormat writtenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String writtenString = writtenNumberFormat.format(written);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalString dagar',
      one: '$totalString dag',
    );
    return '$writtenString av $_temp0';
  }

  @override
  String get statsAverageTitle => 'Genomsnitt';

  @override
  String get statsHighestTitle => 'Högsta värde';

  @override
  String get statsLowestTitle => 'Lägsta värde';

  @override
  String get statsDaysLoggedTitle => 'Dagar med anteckningar';

  @override
  String get statsOfDaysLabel => 'av dagarna';

  @override
  String get statsCustomizeTitle => 'Anpassa';

  @override
  String get errorExternalStorageAccessTitle =>
      'Kommer inte åt den externa lagringen';

  @override
  String get errorExternalStorageAccessDescription =>
      'Om du använder nätverkslagring behöver du kontrollera att tjänsten är tillgänglig och att du är ansluten till nätverket.\n\nAppen kan också ha förlorat åtkomsten till den externa mappen. Öppna inställningarna och välj mappen igen för att ge appen åtkomst.\n\nVarning! Dina ändringar synkroniseras först när appen har åtkomst till den externa lagringen igen.';

  @override
  String get errorExternalStorageAccessContinue =>
      'Fortsätt med den lokala databasen';

  @override
  String get databaseMigrationErrorTitle =>
      'Det gick inte att flytta dina data';

  @override
  String get databaseMigrationErrorDescription =>
      'Dina anteckningar finns kvar, men det gick inte att flytta dem till appens lagringsutrymme.\n\nFörsök igen. Rapportera problemet om det kvarstår.';

  @override
  String get databaseMigrationErrorRetry => 'Försök igen';

  @override
  String get databaseNewerErrorTitle => 'Appen behöver uppdateras';

  @override
  String get databaseNewerErrorDescription =>
      'En nyare version av Daily You har sparat dina data. Den här versionen kan inte öppna dem på ett säkert sätt. Uppdatera appen för att fortsätta.';

  @override
  String get errorReport => 'Rapportera problemet';

  @override
  String get lastModified => 'Senast ändrad';

  @override
  String get writeSomethingHint => 'Skriv något…';

  @override
  String get titleHint => 'Rubrik…';

  @override
  String get deleteLogTitle => 'Ta bort anteckning';

  @override
  String get deleteLogDescription => 'Vill du ta bort den här anteckningen?';

  @override
  String get deletePhotoTitle => 'Delete Photo';

  @override
  String get deletePhotoDescription => 'Do you want to delete this photo?';

  @override
  String get deleteAttachmentTitle => 'Ta bort bilaga';

  @override
  String get deleteAttachmentDescription => 'Vill du ta bort den här bilagan?';

  @override
  String get largeAttachmentWarningTitle => 'Stor bilaga';

  @override
  String get largeAttachmentWarningDescription =>
      'Den här bilagan är stor och gör säkerhetskopian större.';

  @override
  String get dontShowAgain => 'Visa inte igen';

  @override
  String get pageSettingsTitle => 'Inställningar';

  @override
  String get settingsAppearanceTitle => 'Utseende';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Följ systemet';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Veckans första dag';

  @override
  String get settingsCalendarSystem => 'Kalendersystem';

  @override
  String get calendarSystemGregorian => 'Gregorianska kalendern';

  @override
  String get calendarSystemJalali => 'Persiska kalendern (jalali)';

  @override
  String get settingsUseSystemAccentColor => 'Använd systemets accentfärg';

  @override
  String get settingsCustomAccentColor => 'Egen accentfärg';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Visa tillbakablickar';

  @override
  String get settingsChangeMoodIcons => 'Ändra humörikoner';

  @override
  String get moodIconPrompt => 'Ange ett tecken som ikon';

  @override
  String get moodVeryUnpleasant => 'Mycket dåligt';

  @override
  String get moodUnpleasant => 'Dåligt';

  @override
  String get moodNeutral => 'Neutralt';

  @override
  String get moodPleasant => 'Bra';

  @override
  String get moodVeryPleasant => 'Mycket bra';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallerivy';

  @override
  String get settingsHideImagesInGallery => 'Dölj bilder i galleriet';

  @override
  String get settingsHideImages => 'Dölj bilder';

  @override
  String get pageCalendarTitle => 'Kalender';

  @override
  String get viewLayoutList => 'Lista';

  @override
  String get viewLayoutGrid => 'Rutnät';

  @override
  String get settingsNotificationsTitle => 'Aviseringar';

  @override
  String get settingsDailyReminderOnboarding =>
      'Slå på dagliga påminnelser så blir det lättare att skriva regelbundet.';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Appen kommer att be om behörighet att schemalägga alarm så att du kan få påminnelsen vid en slumpmässig tidpunkt eller vid den tid du själv väljer.';

  @override
  String get settingsDailyReminderTitle => 'Daglig påminnelse';

  @override
  String get settingsOnThisDayDescription =>
      'Se vad du skrev den här dagen tidigare år';

  @override
  String get settingsDailyReminderDescription =>
      'En liten påminnelse varje dag';

  @override
  String get settingsReminderTime => 'Tid för påminnelse';

  @override
  String get settingsFixedReminderTimeTitle => 'Fast tid för påminnelsen';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Välj en fast tid för påminnelsen';

  @override
  String get settingsExactAlarmsTitle => 'Tillåt exakta alarm?';

  @override
  String get settingsExactAlarmsDescription =>
      'Påminnelserna kan bli flera minuter försenade om du inte tillåter exakta alarm.';

  @override
  String get settingsAlwaysSendReminderTitle => 'Skicka alltid en påminnelse';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Skicka en påminnelse även om du redan har börjat på en anteckning';

  @override
  String get settingsCustomizeNotificationTitle => 'Anpassa aviseringar';

  @override
  String get settingsTemplatesTitle => 'Mallar';

  @override
  String get settingsDefaultTemplate => 'Standardmall';

  @override
  String get manageTemplates => 'Hantera mallar';

  @override
  String get addTemplate => 'Lägg till en mall';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'Ingen mall';

  @override
  String get noTemplatesDescription => 'Du har inte skapat några mallar än…';

  @override
  String get templateVariableTime => 'Time';

  @override
  String get templateDefaultTimestampTitle => 'Tidsstämpel';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date – $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Dagens sammanfattning';

  @override
  String get templateDefaultSummaryBody =>
      '### Sammanfattning\n- \n\n### Citat\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Reflektion';

  @override
  String get templateDefaultReflectionBody =>
      '### Vad uppskattade du i dag?\n- \n\n### Vad är du tacksam för?\n- \n\n### Vad ser du fram emot?\n- ';

  @override
  String get settingsTagsTitle => 'Taggar';

  @override
  String get manageTags => 'Hantera taggar';

  @override
  String get tagTypeLabelTitle => 'Etikett';

  @override
  String get tagTypeTrackerTitle => 'Mätvärde';

  @override
  String get nameHint => 'Namn';

  @override
  String get tagColorLabel => 'Färg';

  @override
  String get iconPickerTitle => 'Välj ikon';

  @override
  String get iconPickerIconsTab => 'Ikoner';

  @override
  String get iconPickerCustomTab => 'Egen';

  @override
  String get iconPickerSearchHint => 'Sök efter ikoner…';

  @override
  String get colorPickerTitle => 'Välj färg';

  @override
  String get colorPickerPaletteTab => 'Färger';

  @override
  String get iconGroupMoodPeople => 'Humör och människor';

  @override
  String get iconGroupHealth => 'Hälsa';

  @override
  String get iconGroupWorkFinance => 'Arbete och ekonomi';

  @override
  String get iconGroupHabitsGoals => 'Vanor och mål';

  @override
  String get iconGroupNature => 'Natur';

  @override
  String get iconGroupFoodDrink => 'Mat och dryck';

  @override
  String get iconGroupHome => 'Hem';

  @override
  String get iconGroupTravel => 'Resor';

  @override
  String get iconGroupSymbols => 'Symboler';

  @override
  String get tagCategoryLabel => 'Kategori';

  @override
  String get tagLabel => 'Tagg';

  @override
  String get tagCategoryUncategorized => 'Utan kategori';

  @override
  String get newCategoryTitle => 'Ny kategori';

  @override
  String get shareButtonLabel => 'Dela';

  @override
  String get importErrorDescription => 'Det gick inte att importera filen.';

  @override
  String get exportErrorDescription => 'Det gick inte att exportera filen.';

  @override
  String get deleteTitle => 'Ta bort';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Taggen används i $count anteckningar.',
      one: ' Taggen används i en anteckning.',
      zero: '',
    );
    return 'Ta bort ”$name”?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Även de $count taggarna i kategorin tas bort.',
      one: ' Taggen i kategorin tas också bort.',
      zero: '',
    );
    return 'Ta bort ”$name”?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Ta bort ”$name”?';
  }

  @override
  String get filterTagsTitle => 'Filter';

  @override
  String get tagFilterModeAny => 'Minst en av taggarna';

  @override
  String get tagFilterModeAll => 'Alla taggar';

  @override
  String get clearAllFilters => 'Rensa alla filter';

  @override
  String get noTagsFilterLabel => 'Utan taggar';

  @override
  String get clearFilter => 'Rensa';

  @override
  String showLogsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visa $count anteckningar',
      one: 'Visa $count anteckning',
    );
    return '$_temp0';
  }

  @override
  String get filterPillAttachments => 'Bilagor';

  @override
  String get filterPillKeywords => 'Sökord';

  @override
  String get noMoodFilterLabel => 'Utan angivet humör';

  @override
  String get noAttachmentsFilterLabel => 'Utan bilagor';

  @override
  String get noTextFilterLabel => 'Utan text';

  @override
  String partialMatchCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count delträffar',
      one: '$count delträff',
    );
    return '$_temp0';
  }

  @override
  String tagCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taggar',
      one: '$count tagg',
    );
    return '$_temp0';
  }

  @override
  String dateFilterLastMonths(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Senaste $count månaderna',
      one: 'Senaste månaden',
    );
    return '$_temp0';
  }

  @override
  String get dateFilterCustomRange => 'Välj period';

  @override
  String get keywordFilterHint => 'Lägg till ett sökord…';

  @override
  String get keywordFilterMatchAll => 'Alla sökord';

  @override
  String get keywordFilterMatchAny => 'Minst ett sökord';

  @override
  String get keywordFilterMatchCase => 'Skilj på stora och små bokstäver';

  @override
  String keywordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sökord',
      one: '$count sökord',
    );
    return '$_temp0';
  }

  @override
  String dateFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get addTagsTitle => 'Lägg till taggar';

  @override
  String get addTagsSearchHint => 'Sök bland taggar…';

  @override
  String get tagPickerSortManualLabel => 'Manuell ordning';

  @override
  String get tagPickerSortUsageLabel => 'Mest använda först';

  @override
  String get tagFavoriteName => 'Favorit';

  @override
  String get tagEnergyName => 'Energi';

  @override
  String get tagCategoryPeopleName => 'Personer';

  @override
  String get tagCategoryActivitiesName => 'Aktiviteter';

  @override
  String get tagExerciseName => 'Träning';

  @override
  String get tagSocializingName => 'Umgänge';

  @override
  String get tagHobbyName => 'Hobby';

  @override
  String get tagEntertainmentName => 'Nöjen';

  @override
  String get tagDiningName => 'Måltider';

  @override
  String get tagChoresName => 'Hushållssysslor';

  @override
  String get tagCategoryEmotionsName => 'Känslor';

  @override
  String get tagExcitedName => 'Förväntansfull';

  @override
  String get tagGratefulName => 'Tacksam';

  @override
  String get tagCalmName => 'Lugn';

  @override
  String get tagTiredName => 'Trött';

  @override
  String get tagAnxiousName => 'Orolig';

  @override
  String get tagAnnoyedName => 'Irriterad';

  @override
  String get welcomeLogBodyText =>
      '## Välkommen till Daily You\n\n> Varje dag är värd att minnas. Spara ett minne från i dag!\n\n**Daily You** är gratis, har [öppen källkod](https://github.com/Demizo/Daily_You) och får stöd av sina användare. Appen bygger på tanken att din dagbok ska tillhöra dig.\n\n- Ingen reklam\n- Inga låsta funktioner\n- Ingen spårning eller datainsamling\n\nI **Daily You** har du en plats _helt för dig själv_, vare sig du vill skriva dagbok, tänka tillbaka på dagen eller bara anteckna vad som fick dig att le.';

  @override
  String get settingsStorageTitle => 'Lagring och synkronisering';

  @override
  String get settingsImageQuality => 'Image Quality';

  @override
  String get settingsMediaQualityTitle => 'Mediekvalitet';

  @override
  String get imageQualityHigh => 'Hög';

  @override
  String get imageQualityMedium => 'Medel';

  @override
  String get imageQualityLow => 'Låg';

  @override
  String get imageQualityNoCompression => 'Ingen komprimering';

  @override
  String get settingsStorageUsage => 'Använt lagringsutrymme';

  @override
  String get settingsLogFolder => 'Mapp för anteckningar';

  @override
  String get settingsImageFolder => 'Image Folder';

  @override
  String get settingsExternalSyncTitle => 'Synkronisera med en extern plats';

  @override
  String get chooseFolderHint => 'Välj en mapp';

  @override
  String get warningTitle => 'Varning';

  @override
  String get logFolderWarningDescription =>
      'Den valda mappen innehåller redan filen daily_you.db. Om du fortsätter ersätts dina nuvarande anteckningar med dem som finns i filen.';

  @override
  String get errorTitle => 'Fel';

  @override
  String get logFolderErrorDescription => 'Failed to change log folder!';

  @override
  String get imageFolderErrorDescription => 'Failed to change image folder!';

  @override
  String get syncErrorDescription =>
      'Det gick inte att synkronisera med den externa platsen.';

  @override
  String get backupErrorDescription =>
      'Det gick inte att skapa en säkerhetskopia.';

  @override
  String get restoreErrorDescription =>
      'Det gick inte att återställa säkerhetskopian.';

  @override
  String get settingsBackupRestoreTitle =>
      'Säkerhetskopiering och återställning';

  @override
  String get settingsBackup => 'Säkerhetskopiera';

  @override
  String get settingsRestore => 'Återställ';

  @override
  String get settingsRestorePromptDescription =>
      'Om du återställer säkerhetskopian skrivs dina nuvarande data över.';

  @override
  String get settingsBackupPasswordProtect => 'Lösenordsskydda säkerhetskopior';

  @override
  String get backupEncryptedTitle => 'Krypterad säkerhetskopia';

  @override
  String get backupEncryptedContent =>
      'Den här säkerhetskopian är lösenordsskyddad.';

  @override
  String get settingsAutoBackup => 'Automatisk säkerhetskopiering';

  @override
  String get settingsAutoBackupLocation => 'Plats för säkerhetskopior';

  @override
  String get settingsAutoBackupInterval => 'Intervall för säkerhetskopiering';

  @override
  String get settingsAutoBackupIntervalDaily => 'Varje dag';

  @override
  String get settingsAutoBackupIntervalWeekly => 'Varje vecka';

  @override
  String get settingsAutoBackupIntervalMonthly => 'Varje månad';

  @override
  String get settingsAutoBackupMaxCount => 'Antal säkerhetskopior att behålla';

  @override
  String get settingsAutoBackupRequireCharging => 'Endast under laddning';

  @override
  String settingsBackupLast(Object time) {
    return 'Senaste säkerhetskopiering: $time';
  }

  @override
  String get settingsBackupNever => 'Ingen säkerhetskopia har skapats';

  @override
  String settingsAutoBackupNext(Object time) {
    return 'Nästa säkerhetskopiering: $time';
  }

  @override
  String get settingsAutoBackupKeepAll => 'Alla';

  @override
  String get autoBackupFailedTitle => 'Säkerhetskopieringen misslyckades';

  @override
  String tranferStatus(Object percent) {
    return 'Överför… $percent %';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Skapar säkerhetskopia… $percent %';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Återställer säkerhetskopia… $percent %';
  }

  @override
  String encryptingBackupStatus(Object percent) {
    return 'Krypterar säkerhetskopia… $percent %';
  }

  @override
  String decryptingBackupStatus(Object percent) {
    return 'Dekrypterar säkerhetskopia… $percent %';
  }

  @override
  String get cleanUpStatus => 'Rensar…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Flyttar foton… $current av $total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Exportera till ett annat format';

  @override
  String get settingsExportFormatDescription =>
      'Använd inte den exporterade filen som säkerhetskopia.';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get exportIncludeTitle => 'Ta med';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importera från en annan app';

  @override
  String get settingsTranslateCallToAction => 'Alla ska kunna skriva dagbok!';

  @override
  String get settingsHelpTranslate => 'Hjälp till att översätta';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Välj format';

  @override
  String get logFormatDescription =>
      'Andra appars format kanske inte stöder alla funktioner. Rapportera gärna problem, eftersom formaten kan ändras. Dina befintliga anteckningar påverkas inte.';

  @override
  String get formatDailyYouJson => 'Daily You (JSON)';

  @override
  String get formatDaybook => 'Daybook';

  @override
  String get formatDaylio => 'Daylio';

  @override
  String get formatDayOne => 'Day One';

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
  String get formatCsv => 'CSV';

  @override
  String get formatJson => 'JSON';

  @override
  String get settingsDeleteAllLogsTitle => 'Ta bort alla anteckningar';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Vill du ta bort alla dina anteckningar?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Skriv ”$prompt” för att bekräfta. Det går inte att ångra.';
  }

  @override
  String get settingsLanguageTitle => 'Språk';

  @override
  String get settingsAppLanguageTitle => 'Appspråk';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Använd ett annat språk i appen';

  @override
  String get settingsSecurityTitle => 'Säkerhet';

  @override
  String get settingsSecurityRequirePassword => 'Kräv lösenord';

  @override
  String get settingsSecurityEnterPassword => 'Ange lösenord';

  @override
  String get settingsSecuritySetPassword => 'Välj lösenord';

  @override
  String get settingsSecurityChangePassword => 'Ändra lösenord';

  @override
  String get settingsSecurityPassword => 'Lösenord';

  @override
  String get settingsSecurityConfirmPassword => 'Bekräfta lösenord';

  @override
  String get settingsSecurityOldPassword => 'Nuvarande lösenord';

  @override
  String get settingsSecurityIncorrectPassword => 'Fel lösenord';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Lösenorden stämmer inte överens';

  @override
  String get settingsSecurityPasswordWarning =>
      'Om du glömmer lösenordet kan du inte öppna Daily You.';

  @override
  String get requiredPrompt => 'Obligatoriskt';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometrisk upplåsning';

  @override
  String get unlockAppPrompt => 'Lås upp appen';

  @override
  String get settingsAboutTitle => 'Om';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'Licens';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Källkod';

  @override
  String get settingsOpenSourceLicenses => 'Licenser för öppen källkod';

  @override
  String get settingsMadeWithLove => 'Skapad med ❤️';

  @override
  String get settingsConsiderSupporting => 'Stöd gärna projektet';

  @override
  String get supportBannerOpenSourceTitle => 'Daily You har öppen källkod';

  @override
  String get supportBannerFeedbackPrompt => 'Lämna synpunkter';

  @override
  String get imagesTitle => 'Bilder';

  @override
  String get audioTitle => 'Ljud';

  @override
  String get videoTitle => 'Video';

  @override
  String get tagMoodTitle => 'Humör';

  @override
  String get calendarTagDisplayLabel => 'Tagg';

  @override
  String get selectTagTitle => 'Välj tagg';

  @override
  String get labelPresentLabel => 'Med taggen';

  @override
  String get labelAbsentLabel => 'Utan taggen';

  @override
  String get labelCoverageLabel => 'Coverage';

  @override
  String chartDistributionTitle(Object tag) {
    return 'Fördelning av $tag';
  }

  @override
  String get shareAddToLogPickerTitle => 'Välj en anteckning';

  @override
  String get attachmentAddErrorDescription =>
      'Det gick inte att lägga till bilagan.';

  @override
  String get attachmentLoadFailed => 'Det gick inte att öppna bilagan.';

  @override
  String get attachmentNoAppToOpen => 'Ingen app kan öppna bilagan.';

  @override
  String get recorderDiscardTitle => 'Kassera inspelningen?';

  @override
  String get recorderDiscardDescription => 'Inspelningen tas bort.';

  @override
  String get recorderDiscardAction => 'Kassera';

  @override
  String get recorderPermissionDenied =>
      'Ge appen åtkomst till mikrofonen för att spela in ljud.';

  @override
  String get recorderErrorDescription => 'Det gick inte att spela in ljud.';

  @override
  String get gallerySelectAll => 'Markera alla';

  @override
  String get gallerySelectAction => 'Markera';

  @override
  String get galleryOpenAction => 'Öppna';

  @override
  String deleteLogsMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vill du ta bort $count anteckningar? Tillhörande bilagor tas också bort.',
      one:
          'Vill du ta bort $count anteckning? Tillhörande bilagor tas också bort.',
    );
    return '$_temp0';
  }

  @override
  String get newLogAction => 'Ny anteckning';

  @override
  String get removeTagsTitle => 'Ta bort taggar';

  @override
  String get discardChangesTitle => 'Kassera ändringarna?';

  @override
  String get discardChangesDescription => 'Dina ändringar går förlorade.';

  @override
  String get applyButtonLabel => 'Verkställ';

  @override
  String addTagsConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vill du lägga till de valda taggarna i $count anteckningar?',
      one: 'Vill du lägga till de valda taggarna i $count anteckning?',
    );
    return '$_temp0';
  }

  @override
  String removeTagsConfirmMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vill du ta bort de valda taggarna från $count anteckningar?',
      one: 'Vill du ta bort de valda taggarna från $count anteckning?',
    );
    return '$_temp0';
  }

  @override
  String selectPartialMatchesMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vill du också markera $count delträffar?',
      one: 'Vill du också markera $count delträff?',
    );
    return '$_temp0';
  }

  @override
  String get selectExactMatchesOnly => 'Endast exakta träffar';

  @override
  String get selectIncludingPartialMatches => 'Ta med delträffar';

  @override
  String get onboardingSkip => 'Hoppa över';

  @override
  String get onboardingContinue => 'Fortsätt';

  @override
  String get onboardingFinish => 'Börja skriva dagbok';

  @override
  String get onboardingImportTitle => 'Har du använt en annan dagboksapp?';

  @override
  String get onboardingImportDescription =>
      'Ta med dina tidigare anteckningar eller börja med en tom dagbok.';

  @override
  String get onboardingStorageNote =>
      'Du kan ändra de här valen senare i inställningarna.';

  @override
  String get onboardingWelcomeTitle => 'Välkommen till Daily You';

  @override
  String get onboardingWelcomeDescription => 'Varje dag är värd att minnas.';

  @override
  String get onboardingRemindersTitle => 'Gör det till en vana';

  @override
  String get onboardingStorageTitle => 'Skydda dina anteckningar';

  @override
  String get onboardingRestore => 'Återställ från en säkerhetskopia';

  @override
  String get onboardingMoodsCustomize => 'Anpassa humörskalan';

  @override
  String get onboardingRemindersDescription =>
      'Få en påminnelse om att skriva dagbok vid en slumpmässig tidpunkt eller på en tid som du själv väljer.';
}
