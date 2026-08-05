// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'இன்றைய பதிவு!';

  @override
  String get dailyReminderDescription => 'உங்கள் தினசரி பதிவை மேற்கொள்ளுங்கள்…';

  @override
  String get actionTakePhoto => 'புகைப்படம் எடு';

  @override
  String get actionToday => 'இன்று';

  @override
  String get actionOtherDay => 'மற்ற நாள்';

  @override
  String get pageHomeTitle => 'முகப்பு';

  @override
  String get jumpToMonthTitle => 'Jump to month';

  @override
  String get jumpToLogTitle => 'Jump to log';

  @override
  String get flashbacksTitle => 'நினைவலைகள்';

  @override
  String get settingsFlashbacksExcludeBadDays => 'மோசமான நாட்களை தவிர்க்க';

  @override
  String get flaskbacksEmpty => 'இதுவரை நினைவலைகள் எதுவும் இல்லை …';

  @override
  String get flashbackGoodDay => 'ஒரு நல்ல நாள்';

  @override
  String get flashbackRandomDay => 'குறிப்பிடப்படாத ஒரு நாள்';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வாரங்களுக்கு முன்பு',
      one: '$count வாரம் முன்பு',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்களுக்கு முன்பு',
      one: '$count Month ago',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ஆண்டுகளுக்கு முன்பு',
      one: '$count வருடம் முன்பு',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'இந்த நாளில்';

  @override
  String get pageGalleryTitle => 'தொகுப்பு';

  @override
  String get searchLogsHint => 'தேடல் பதிவுகள்…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பதிவுகள்',
      one: '$count log',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்கள்',
      one: '$count நாள்',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count சொற்கள்',
      one: '$count word',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'பதிவுகள் இல்லை…';

  @override
  String get noResults => 'No Results…';

  @override
  String get sortDateTitle => 'திகதி';

  @override
  String get sortOrderAscendingTitle => 'ஏறுதல்';

  @override
  String get sortOrderDescendingTitle => 'இறங்கு';

  @override
  String get pageStatisticsTitle => 'புள்ளிவிவரங்கள்';

  @override
  String get statisticsNotEnoughData => 'போதுமான தரவு இல்லை…';

  @override
  String get statisticsRangeOneMonth => '1 மாதம்';

  @override
  String get statisticsRangeSixMonths => '6 மாதங்கள்';

  @override
  String get statisticsRangeOneYear => '1 வருடம்';

  @override
  String get statisticsRangeAllTime => 'எல்லா நேரமும்';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag சுருக்கம்';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag நாள் வாரியாக';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag காலப்போக்கில்';
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
      other: 'ஒரு மோசமான நாளிலிருந்து நாட்கள் $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'வெளிப்புற சேமிப்பகத்தை அணுக முடியவில்லை';

  @override
  String get errorExternalStorageAccessDescription =>
      'நீங்கள் பிணையம் சேமிப்பகத்தைப் பயன்படுத்துகிறீர்கள் என்றால், பணி ஆன்லைனில் இருப்பதையும் உங்களுக்கு பிணையம் அணுகல் இருப்பதையும் உறுதிப்படுத்திக் கொள்ளுங்கள். \n\nஇல்லையெனில், ஆப்ச் வெளிப்புற கோப்புறைக்கான அனுமதிகளை இழந்திருக்கலாம். அமைப்புகளுக்குச் சென்று, அணுகலை வழங்க வெளிப்புற கோப்புறையை மீண்டும் தேர்ந்தெடுக்கவும். \n\nஎச்சரிக்கை, வெளிப்புற சேமிப்பக இருப்பிடத்திற்கான அணுகலை மீட்டெடுக்கும் வரை மாற்றங்கள் ஒத்திசைக்கப்படாது!';

  @override
  String get errorExternalStorageAccessContinue =>
      'உள்ளக தரவுத்தளத்துடன் தொடரவும்';

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
  String get lastModified => 'மாற்றியமைக்கப்பட்ட';

  @override
  String get writeSomethingHint => 'ஏதாவது எழுது…';

  @override
  String get titleHint => 'தலைப்பு…';

  @override
  String get deleteLogTitle => 'பதிவை நீக்கு';

  @override
  String get deleteLogDescription => 'இந்தப் பதிவை நீக்க வேண்டுமா?';

  @override
  String get deletePhotoTitle => 'புகைப்படத்தை நீக்கு';

  @override
  String get deletePhotoDescription => 'இந்தப் படத்தை நீக்க வேண்டுமா?';

  @override
  String get pageSettingsTitle => 'அமைப்புகள்';

  @override
  String get settingsAppearanceTitle => 'தோற்றம்';

  @override
  String get settingsTheme => 'கருப்பொருள்';

  @override
  String get themeSystem => 'மண்டலம்';

  @override
  String get themeLight => 'ஒளி';

  @override
  String get themeDark => 'இருள்';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'வாரத்தின் முதல் நாள்';

  @override
  String get settingsCalendarSystem => 'காலண்டர் அமைப்பு';

  @override
  String get calendarSystemGregorian => 'கிரிகோரியன்';

  @override
  String get calendarSystemJalali => 'சலாலி';

  @override
  String get settingsUseSystemAccentColor =>
      'கணினி உச்சரிப்பு நிறத்தைப் பயன்படுத்தவும்';

  @override
  String get settingsCustomAccentColor => 'தனிப்பயன் உச்சரிப்பு நிறம்';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'ஃப்ளாச்பேக்குகளைக் காட்டு';

  @override
  String get settingsChangeMoodIcons => 'மூட் ஐகான்களை மாற்றவும்';

  @override
  String get moodIconPrompt => 'ஐகானை உள்ளிடவும்';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'கேலரி காட்சி தளவமைப்பு';

  @override
  String get settingsHideImagesInGallery => 'கேலரியில் படங்களை மறை';

  @override
  String get settingsHideImages => 'படங்களை மறை';

  @override
  String get pageCalendarTitle => 'நாள்காட்டி';

  @override
  String get viewLayoutList => 'பட்டியல்';

  @override
  String get viewLayoutGrid => 'வலைவாய்';

  @override
  String get settingsNotificationsTitle => 'அறிவிப்புகள்';

  @override
  String get settingsDailyReminderOnboarding =>
      'உங்களை சீராக வைத்திருக்க நாள்தோறும் நினைவூட்டல்களை இயக்கவும்!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'சீரற்ற தருணத்தில் அல்லது நீங்கள் விரும்பும் நேரத்தில் நினைவூட்டலை அனுப்ப \'அட்டவணை அலாரங்கள்\' இசைவு கோரப்படும்.';

  @override
  String get settingsDailyReminderTitle => 'நாள்தோறும் நினைவூட்டல்';

  @override
  String get settingsOnThisDayDescription =>
      'கடந்த கால நினைவுகளை மீண்டும் பார்க்கவும்';

  @override
  String get settingsDailyReminderDescription =>
      'ஒவ்வொரு நாளும் ஒரு மென்மையான நினைவூட்டல்';

  @override
  String get settingsReminderTime => 'நினைவூட்டல் நேரம்';

  @override
  String get settingsFixedReminderTimeTitle => 'நிலையான நினைவூட்டல் நேரம்';

  @override
  String get settingsFixedReminderTimeDescription =>
      'நினைவூட்டலுக்கு ஒரு குறிப்பிட்ட நேரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get settingsAlwaysSendReminderTitle =>
      'எப்போதும் நினைவூட்டலை அனுப்பவும்';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'பதிவு ஏற்கனவே தொடங்கப்பட்டிருந்தாலும் நினைவூட்டலை அனுப்பவும்';

  @override
  String get settingsCustomizeNotificationTitle =>
      'அறிவிப்புகளைத் தனிப்பயனாக்கு';

  @override
  String get settingsTemplatesTitle => 'வார்ப்புருக்கள்';

  @override
  String get settingsDefaultTemplate => 'இயல்புநிலை டெம்ப்ளேட்';

  @override
  String get manageTemplates => 'டெம்ப்ளேட்களை நிர்வகிக்கவும்';

  @override
  String get addTemplate => 'ஒரு டெம்ப்ளேட்டைச் சேர்க்கவும்';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'எதுவுமில்லை';

  @override
  String get noTemplatesDescription =>
      'இதுவரை டெம்ப்ளேட்கள் எதுவும் உருவாக்கப்படவில்லை…';

  @override
  String get templateVariableTime => 'நேரம்';

  @override
  String get templateDefaultTimestampTitle => 'நேர முத்திரை';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'நாள் சுருக்கம்';

  @override
  String get templateDefaultSummaryBody =>
      '### சுருக்கம் \n- \n\n### மேற்கோள் \n> ';

  @override
  String get templateDefaultReflectionTitle => 'பிரதிபலிப்பு';

  @override
  String get templateDefaultReflectionBody =>
      '### இன்று நீங்கள் எதைப் பற்றி ரசித்தீர்கள்? \n- \n\n### நீங்கள் எதற்கு நன்றி கூறுகிறீர்கள்? \n- \n\n### நீங்கள் என்ன எதிர்பார்க்கிறீர்கள்? \n- ';

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
  String get tagCategoryUncategorized => 'Uncategorized';

  @override
  String get newCategoryTitle => 'New Category';

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
  String get settingsStorageTitle => 'சேமிப்பு';

  @override
  String get settingsImageQuality => 'படத்தின் தகுதி';

  @override
  String get imageQualityHigh => 'உயர்';

  @override
  String get imageQualityMedium => 'சராசரி';

  @override
  String get imageQualityLow => 'குறைந்த';

  @override
  String get imageQualityNoCompression => 'சுருக்கம் இல்லை';

  @override
  String get settingsLogFolder => 'பதிவு கோப்புறை';

  @override
  String get settingsImageFolder => 'படக் கோப்புறை';

  @override
  String get warningTitle => 'எச்சரிக்கை';

  @override
  String get logFolderWarningDescription =>
      'தேர்ந்தெடுக்கப்பட்ட கோப்புறையில் ஏற்கனவே \'daily_you.db\' கோப்பு இருந்தால், அது ஏற்கனவே உள்ள உங்கள் பதிவுகளை மேலெழுதப் பயன்படுத்தப்படும்!';

  @override
  String get errorTitle => 'பிழை';

  @override
  String get logFolderErrorDescription => 'பதிவு கோப்புறையை மாற்ற முடியவில்லை!';

  @override
  String get imageFolderErrorDescription => 'பட கோப்புறையை மாற்ற முடியவில்லை!';

  @override
  String get backupErrorDescription => 'காப்புப்பிரதியை உருவாக்குவதில் தோல்வி!';

  @override
  String get restoreErrorDescription =>
      'காப்புப்பிரதியை மீட்டெடுப்பதில் தோல்வி!';

  @override
  String get settingsBackupRestoreTitle => 'காப்புப்பிரதி & மீட்டமை';

  @override
  String get settingsBackup => 'காப்புப்பிரதி';

  @override
  String get settingsRestore => 'மீட்டமை';

  @override
  String get settingsRestorePromptDescription =>
      'காப்புப்பிரதியை மீட்டெடுப்பது ஏற்கனவே உள்ள உங்கள் தரவை மேலெழுதும்!';

  @override
  String tranferStatus(Object percent) {
    return 'மாற்றுகிறது… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'காப்புப்பிரதியை உருவாக்குகிறது… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'காப்புப்பிரதியை மீட்டெடுக்கிறது… $percent%';
  }

  @override
  String get cleanUpStatus => 'தூய்மை செய்கிறது…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat =>
      'மற்றொரு வடிவத்திற்கு ஏற்றுமதி செய்யவும்';

  @override
  String get settingsExportFormatDescription =>
      'இதை காப்புப்பிரதியாகப் பயன்படுத்தக் கூடாது!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp =>
      'மற்றொரு பயன்பாட்டிலிருந்து இறக்குமதி செய்யவும்';

  @override
  String get settingsTranslateCallToAction =>
      'ஒவ்வொருவரும் ஒரு பத்திரிகையை அணுக வேண்டும்!';

  @override
  String get settingsHelpTranslate => 'மொழிபெயர்க்க உதவுங்கள்';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'வடிவமைப்பைத் தேர்ந்தெடுக்கவும்';

  @override
  String get logFormatDescription =>
      'மற்றொரு ஆப்சின் வடிவம் அனைத்து அம்சங்களையும் ஆதரிக்காமல் இருக்கலாம். மூன்றாம் தரப்பு வடிவங்கள் எந்த நேரத்திலும் மாறக்கூடும் என்பதால், ஏதேனும் சிக்கல்களைப் புகாரளிக்கவும். இது ஏற்கனவே உள்ள பதிவுகளை பாதிக்காது!';

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
  String get formatMarkdown => 'மார்க் பேரூர்';

  @override
  String get settingsDeleteAllLogsTitle => 'அனைத்து பதிவுகளையும் நீக்கு';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Do you want பெறுநர் நீக்கு அனைத்தும் of your logs?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'உறுதிப்படுத்த \'$prompt\' ஐ உள்ளிடவும். இதை செயல்தவிர்க்க முடியாது!';
  }

  @override
  String get settingsLanguageTitle => 'மொழி';

  @override
  String get settingsAppLanguageTitle => 'பயன்பாட்டு மொழி';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'பயன்பாட்டு மொழியை மேலெழுதவும்';

  @override
  String get settingsSecurityTitle => 'பாதுகாப்பு';

  @override
  String get settingsSecurityRequirePassword => 'கடவுச்சொல் தேவை';

  @override
  String get settingsSecurityEnterPassword => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get settingsSecuritySetPassword => 'கடவுச்சொல்லை அமைக்கவும்';

  @override
  String get settingsSecurityChangePassword => 'கடவுச்சொல்லை மாற்றவும்';

  @override
  String get settingsSecurityPassword => 'கடவுச்சொல்';

  @override
  String get settingsSecurityConfirmPassword =>
      'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get settingsSecurityOldPassword => 'பழைய கடவுச்சொல்';

  @override
  String get settingsSecurityIncorrectPassword => 'தவறான கடவுச்சொல்';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get requiredPrompt => 'தேவை';

  @override
  String get settingsSecurityBiometricUnlock => 'பயோமெட்ரிக் திறத்தல்';

  @override
  String get unlockAppPrompt => 'பயன்பாட்டைத் திறக்கவும்';

  @override
  String get settingsAboutTitle => 'பற்றி';

  @override
  String get settingsVersion => 'பதிப்பு';

  @override
  String get settingsLicense => 'உரிமம்';

  @override
  String get licenseGPLv3 => 'சிபிஎல்-3.0';

  @override
  String get settingsSourceCode => 'மூலக் குறியீடு';

  @override
  String get settingsMadeWithLove => '❤️ கொண்டு உருவாக்கப்பட்டது';

  @override
  String get settingsConsiderSupporting => 'ஆதரிப்பதை கருத்தில் கொள்ளுங்கள்';

  @override
  String get imagesTitle => 'படங்கள்';

  @override
  String get tagMoodTitle => 'மனநிலை';

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
