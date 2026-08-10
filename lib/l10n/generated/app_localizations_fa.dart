// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'امروز را ثبت کن!';

  @override
  String get dailyReminderDescription => 'گزارش روزانه ات رو ثبت کن…';

  @override
  String get actionTakePhoto => 'عکس بگیر';

  @override
  String get actionToday => 'امروز';

  @override
  String get actionOtherDay => 'روز دیگر';

  @override
  String get pageHomeTitle => 'خانه';

  @override
  String get jumpToMonthTitle => 'پرش به ماه';

  @override
  String get jumpToLogTitle => 'پرش به تاریخچه';

  @override
  String get flashbacksTitle => 'فلش بک';

  @override
  String get settingsFlashbacksExcludeBadDays => 'مستثنی کردن روزهای بد';

  @override
  String get flaskbacksEmpty => 'هیچ فلش بکی وجود ندارد…';

  @override
  String get flashbackGoodDay => 'یک روز خوب';

  @override
  String get flashbackRandomDay => 'یک روز تصادفی';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count هفته قبل',
      one: '$count هفته قبل',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ماه قبل',
      one: '$count ماه قبل',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سال قبل',
      one: '$count سال قبل',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'در این روز';

  @override
  String get pageGalleryTitle => 'گالری';

  @override
  String get searchLogsHint => 'تاریخچه جستجوها…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گزارش ها',
      one: '$count گزارش',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز ها',
      one: '$count روز',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کلمات',
      one: '$count کلمه',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'تاریخچه ای وجود ندارد…';

  @override
  String get noResults => 'بدون نتیجه…';

  @override
  String get sortDateTitle => 'تاریخ';

  @override
  String get sortOrderAscendingTitle => 'افزایشی';

  @override
  String get sortOrderDescendingTitle => 'کاهشی';

  @override
  String get pageStatisticsTitle => 'آمارها';

  @override
  String get statisticsNotEnoughData => 'اطلاعات کافی نیست …';

  @override
  String get statisticsRangeOneMonth => '۱ ماه';

  @override
  String get statisticsRangeSixMonths => '۶ ماه';

  @override
  String get statisticsRangeOneYear => '۱ سال';

  @override
  String get statisticsRangeAllTime => 'کل بازه زمانی';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag خلاصه';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag براساس روز';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag در طول زمان';
  }

  @override
  String get chartGroupingLabel => 'گروه‌بندی بر اساس';

  @override
  String get chartGroupingDay => 'روز';

  @override
  String get chartGroupingWeek => 'هفته';

  @override
  String get chartGroupingMonth => 'ماه';

  @override
  String get chartGroupingYear => 'سال';

  @override
  String get chartSmoothingLabel => 'Smoothing';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'توالی کنونی $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'طولانی ترین پیوستگی $count',
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
      other: 'روز از اخرین روز بد $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'امکان دسترسی به حافظه خارجی وجود ندارد';

  @override
  String get errorExternalStorageAccessDescription =>
      'اگر از فضای ذخیره‌سازی شبکه استفاده می‌کنید، مطمئن شوید سرویس آنلاین است و به شبکه دسترسی دارید.\n\nدر غیر این صورت، ممکن است اپلیکیشن مجوزهای مربوط به پوشهٔ خارجی ز دست داده باشد. به بخش تنظیمات بروید و پوشهٔ خارجی را دوباره انتخاب کنید تا دسترسی مجدد بدهید.\n\nهشدار: تا زمانی که دسترسی به محل ذخیره‌سازی خارجی را بازیابی نکنید، تغییرات همگام‌سازی نخواهند شد!';

  @override
  String get errorExternalStorageAccessContinue => 'ادامه با پایگاه داده محلی';

  @override
  String get databaseMigrationErrorTitle =>
      'نتوانستم داده‌های شما را منتقل کنم';

  @override
  String get databaseMigrationErrorDescription =>
      'ورودی‌های شما امن هستند اما امکان انتقال آنها به حافظه برنامه وجود ندارد.\n\nدوباره امتحان کنید و اگر مشکل ادامه داشت، آن را گزارش دهید.';

  @override
  String get databaseMigrationErrorRetry => 'تلاش دوباره';

  @override
  String get errorReport => 'گزارش مشکل';

  @override
  String get lastModified => 'تغییریافته';

  @override
  String get writeSomethingHint => 'چیزی بنویسید…';

  @override
  String get titleHint => 'عنوان…';

  @override
  String get deleteLogTitle => 'حذف تاریخچه';

  @override
  String get deleteLogDescription => 'ایا میخواهید این تاریچه را پاک کنید؟';

  @override
  String get deletePhotoTitle => 'حذف عکس';

  @override
  String get deletePhotoDescription => 'ایا میخواهید این عکس را حذف کنید؟';

  @override
  String get pageSettingsTitle => 'تنظیمات';

  @override
  String get settingsAppearanceTitle => 'ظاهر';

  @override
  String get settingsTheme => '‏تم';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeAmoled => 'امولد';

  @override
  String get settingsFirstDayOfWeek => 'روز اول هفته';

  @override
  String get settingsCalendarSystem => 'سیستم تقویم';

  @override
  String get calendarSystemGregorian => 'میلادی';

  @override
  String get calendarSystemJalali => 'شمسی (جلالی)';

  @override
  String get settingsUseSystemAccentColor => 'استفاده از رنگ بندی سیستم';

  @override
  String get settingsCustomAccentColor => 'شخصی سازی رنگ بندی';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'نمایش فلش بک ها';

  @override
  String get settingsChangeMoodIcons => 'تغییر آیکن حس و حال';

  @override
  String get moodIconPrompt => 'یک آیکون وارد کنید';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'سبک نمایش گالری';

  @override
  String get settingsHideImagesInGallery => 'پنهان کردن عکس های درون گالری';

  @override
  String get settingsHideImages => 'پنهان کردن عکس ها';

  @override
  String get pageCalendarTitle => 'تقویم';

  @override
  String get viewLayoutList => 'لیست';

  @override
  String get viewLayoutGrid => 'مشبک';

  @override
  String get settingsNotificationsTitle => 'نوتیفیکشن ها';

  @override
  String get settingsDailyReminderOnboarding =>
      'یاداوری روزانه را فعال کن تا همیشه منظم باشی!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'مجوز «برنامه‌ریزی هشدارها» درخواست می‌شود تا یادآوری را در یک لحظهٔ تصادفی یا در زمان دلخواه شما ارسال کند.';

  @override
  String get settingsDailyReminderTitle => 'یادآوری روزانه';

  @override
  String get settingsOnThisDayDescription => 'مرور خاطرات گذشته';

  @override
  String get settingsDailyReminderDescription => 'یه یادآوری کوچولو روزانه';

  @override
  String get settingsReminderTime => 'زمان یادآوری';

  @override
  String get settingsFixedReminderTimeTitle => 'زمان یادآوری ثابت';

  @override
  String get settingsFixedReminderTimeDescription =>
      'یک زمان ثابت برای یادآوری انتخاب کنید';

  @override
  String get settingsAlwaysSendReminderTitle => 'همیشه یادآور ارسال شود';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'یادآوری را بفرست، حتی اگر قبلاً یک لاگ شروع شده باشد';

  @override
  String get settingsCustomizeNotificationTitle => 'سفارشی سازی اعلان ها';

  @override
  String get settingsTemplatesTitle => '‎الگوها';

  @override
  String get settingsDefaultTemplate => 'الگوی پیشفرض';

  @override
  String get manageTemplates => 'مدیریت الگوها';

  @override
  String get addTemplate => 'افزودن یک الگو';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'هیچ';

  @override
  String get noTemplatesDescription => 'هیچ الگویی هنوز ایجاد نشده است…';

  @override
  String get templateVariableTime => 'زمان';

  @override
  String get templateDefaultTimestampTitle => 'زمان ثبت';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'خلاصه روز';

  @override
  String get templateDefaultSummaryBody => '### خلاصه\n- \n\n### نقل‌قول\n> ';

  @override
  String get templateDefaultReflectionTitle => 'بازتاب';

  @override
  String get templateDefaultReflectionBody =>
      '### چه چیزی امروز لذت بخش بود؟\n- \n\n### بابت چه چیزی شکرگزارید؟\n- \n\n### منتظر چه چیزی هستید؟\n- ';

  @override
  String get settingsTagsTitle => 'برچسب‌ها';

  @override
  String get manageTags => 'مدیریت برچسب‌ها';

  @override
  String get tagTypeLabelTitle => 'Label';

  @override
  String get tagTypeTrackerTitle => 'Tracker';

  @override
  String get nameHint => 'نام';

  @override
  String get tagColorLabel => 'رنگ';

  @override
  String get iconPickerTitle => 'انتخاب آیکن';

  @override
  String get iconPickerIconsTab => 'آیکن‌ها';

  @override
  String get iconPickerCustomTab => 'شخصی‌سازی';

  @override
  String get iconPickerSearchHint => 'جستجوی آیکن‌ها…';

  @override
  String get colorPickerTitle => 'انتخاب رنگ';

  @override
  String get colorPickerPaletteTab => 'رنگ‌ها';

  @override
  String get iconGroupMoodPeople => 'Mood & People';

  @override
  String get iconGroupHealth => 'سلامت';

  @override
  String get iconGroupWorkFinance => 'کار و امور مالی';

  @override
  String get iconGroupHabitsGoals => 'عادات و اهداف';

  @override
  String get iconGroupNature => 'طبیعت';

  @override
  String get iconGroupFoodDrink => 'غذا و نوشیدنی‌';

  @override
  String get iconGroupHome => 'خانه';

  @override
  String get iconGroupTravel => 'سفر';

  @override
  String get iconGroupSymbols => 'نمادها';

  @override
  String get tagCategoryLabel => 'دسته بندی';

  @override
  String get tagCategoryUncategorized => 'دسته بندی نشده';

  @override
  String get newCategoryTitle => 'دسته بندی جدید';

  @override
  String get deleteTitle => 'پاک کردن';

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
  String get filterTagsTitle => 'فیلتر';

  @override
  String get tagFilterModeAny => 'هر برچسبی';

  @override
  String get tagFilterModeAll => 'همه برچسب‌ها';

  @override
  String get clearAllFilters => 'پاک کردن همه';

  @override
  String get noTagsFilterLabel => 'بدون برچسب';

  @override
  String get addTagsTitle => 'افزودن برچسب';

  @override
  String get addTagsSearchHint => 'جستجوی برچسب‌ها…';

  @override
  String get tagPickerSortManualLabel => 'ترتیب دستی';

  @override
  String get tagPickerSortUsageLabel => 'مرتب کردن بر اساس استفاده';

  @override
  String get tagFavoriteName => 'مورد علاقه‌ها';

  @override
  String get tagEnergyName => 'انرژی';

  @override
  String get tagCategoryActivitiesName => 'فعالیت‌ها';

  @override
  String get tagExerciseName => 'ورزش';

  @override
  String get tagSocializingName => 'معاشرت';

  @override
  String get tagHobbyName => '';

  @override
  String get tagEntertainmentName => 'Entertainment';

  @override
  String get tagDiningName => 'Dining';

  @override
  String get tagChoresName => 'Chores';

  @override
  String get tagCategoryEmotionsName => 'احساساتی';

  @override
  String get tagExcitedName => 'هیجان‌زده';

  @override
  String get tagGratefulName => 'سپاسگزار';

  @override
  String get tagCalmName => 'آرام';

  @override
  String get tagTiredName => 'خسته';

  @override
  String get tagAnxiousName => 'مضطرب';

  @override
  String get tagAnnoyedName => 'آزرده خاطر';

  @override
  String get welcomeLogBodyText =>
      '## به Daily You خوش آمدید\n\n> هر روز ارزش به خاطر سپردن دارد، آن را ثبت کنید!\n\n**Daily You** رایگان، [متن‌باز] (https://github.com/Demizo/Daily_You) و تحت حمایت جامعه است. بر اساس این باور ساخته شده است که دفتر خاطرات شما باید متعلق به خودتان باشد، نه یک محصول:\n\n- بدون تبلیغات\n- بدون ویژگی‌های قفل‌شده\n- بدون ردیابی یا جمع‌آوری داده‌ها\n\nچه در حال نوشتن خاطرات روزانه باشید، چه در حال تفکر، یا فقط یادداشت کردن آنچه که باعث لبخند شما شده است، **Daily You** به شما یک فضای خصوصی می‌دهد که _واقعاً متعلق به خودتان_ است.';

  @override
  String get settingsStorageTitle => 'ذخیره سازی';

  @override
  String get settingsImageQuality => 'کیفیت تصویر';

  @override
  String get imageQualityHigh => 'زیاد';

  @override
  String get imageQualityMedium => 'متوسط';

  @override
  String get imageQualityLow => 'پایین';

  @override
  String get imageQualityNoCompression => 'بدون فشرده سازی';

  @override
  String get settingsLogFolder => 'پوشه گزارش';

  @override
  String get settingsImageFolder => 'پوشه تصاویر';

  @override
  String get warningTitle => 'هشدار';

  @override
  String get logFolderWarningDescription =>
      'اگر پوشهٔ انتخابی از قبل شامل فایل \'daily_you.db\' باشد، از آن فایل برای بازنویسی (overwrite) گزارش های موجود شما استفاده خواهد شد!';

  @override
  String get errorTitle => 'خطا';

  @override
  String get logFolderErrorDescription => 'خطا در تغییر پوشه گزارش!';

  @override
  String get imageFolderErrorDescription => 'خطا در تغییر پوشه عکس!';

  @override
  String get backupErrorDescription => 'خطا در پشتیبانی گیری!';

  @override
  String get restoreErrorDescription => 'خطا در بازیابی پشتیبانی!';

  @override
  String get settingsBackupRestoreTitle => 'پشتیبان گیری و بازیابی';

  @override
  String get settingsBackup => 'پشتیبان گیری';

  @override
  String get settingsRestore => 'بازنشانی';

  @override
  String get settingsRestorePromptDescription =>
      'بازیابی پشتیبان اطلاعات موجود را بازنویسی خواهد کرد!';

  @override
  String tranferStatus(Object percent) {
    return 'درحال انتقال… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'درحال پشتیبانی گیری… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'درحال بازیابی اطلاعات… $percent%';
  }

  @override
  String get cleanUpStatus => 'در حال تمیز کردن …';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'در حال انتقال تصاویر… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'خروجی به فرمت دیگر';

  @override
  String get settingsExportFormatDescription =>
      'این نباید به عنوان یک پشتیبان استفاده شود!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'ورودی از یک برنامه دیگر';

  @override
  String get settingsTranslateCallToAction =>
      'همه باید به یه یادداشت روزانه دسترسی داشته باشه!';

  @override
  String get settingsHelpTranslate => 'کمک به ترجمه';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'انتخاب فرمت';

  @override
  String get logFormatDescription =>
      'فرمت اپلیکیشن دیگر ممکن است همهٔ قابلیت‌ها را پشتیبانی نکند. لطفاً مشکلات را گزارش دهید، چون فرمت‌های شخص ثالث ممکن است هر لحظه تغییر کنند. این کار به گزارش های فعلی شما آسیبی نمی‌زند!';

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
  String get formatMarkdown => 'مارک داون';

  @override
  String get settingsDeleteAllLogsTitle => 'حذف همه گزارش ها';

  @override
  String get settingsDeleteAllLogsDescription =>
      'ایا می‌خواهید همه گزارش ها را حذف کنید؟';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'برای تأیید \'$prompt\' را وارد کنید. این عمل قابل بازگشت نیست!';
  }

  @override
  String get settingsLanguageTitle => 'زبان';

  @override
  String get settingsAppLanguageTitle => 'زبان برنامه';

  @override
  String get settingsOverrideAppLanguageTitle => 'نادیده گرفتن زبان برنامه';

  @override
  String get settingsSecurityTitle => 'امنیت';

  @override
  String get settingsSecurityRequirePassword => 'نیاز به گذرواژه';

  @override
  String get settingsSecurityEnterPassword => 'ورود گذرواژه';

  @override
  String get settingsSecuritySetPassword => 'تعیین گذرواژه';

  @override
  String get settingsSecurityChangePassword => 'تغییر گذرواژه';

  @override
  String get settingsSecurityPassword => 'گذرواژه';

  @override
  String get settingsSecurityConfirmPassword => 'تایید گذرواژه';

  @override
  String get settingsSecurityOldPassword => 'گذرواژه قدیمی';

  @override
  String get settingsSecurityIncorrectPassword => 'رمز اشتباه';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'گذرواژه منطبق نیست';

  @override
  String get requiredPrompt => 'نیاز است';

  @override
  String get settingsSecurityBiometricUnlock => 'بازکردن بایومتریک';

  @override
  String get unlockAppPrompt => 'قفل برنامه را باز کنید';

  @override
  String get settingsAboutTitle => 'درباره';

  @override
  String get settingsVersion => 'نسخه';

  @override
  String get settingsLicense => 'مجوز';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'کد منبع';

  @override
  String get settingsMadeWithLove => 'ساخته شده با ❤️';

  @override
  String get settingsConsiderSupporting => 'حمایت را در نظر بگیرید';

  @override
  String get imagesTitle => 'تصاویر';

  @override
  String get tagMoodTitle => 'حس و حال';

  @override
  String get calendarTagDisplayLabel => 'برچسب';

  @override
  String get selectTagTitle => 'انتخاب برچسب';

  @override
  String get labelPresentLabel => 'حال حاضر';

  @override
  String get labelAbsentLabel => 'غایب';

  @override
  String get labelCoverageLabel => 'پوشش';

  @override
  String chartDistributionTitle(Object tag) {
    return '$tag توزیع';
  }
}
