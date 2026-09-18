// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'سَجِّل اليوم!';

  @override
  String get dailyReminderDescription => 'خذ سجل يومياتك…';

  @override
  String get actionTakePhoto => 'التقط صورة';

  @override
  String get actionToday => 'اليوم';

  @override
  String get actionOtherDay => 'يوم آخر';

  @override
  String get pageHomeTitle => 'الرئيسية';

  @override
  String get jumpToMonthTitle => 'ذهاب إلى الشهر';

  @override
  String get jumpToLogTitle => 'الإنتقال إلى السجل';

  @override
  String get flashbacksTitle => 'الذكريات';

  @override
  String get settingsFlashbacksExcludeBadDays => 'استبعد الأيام السيئة';

  @override
  String get flaskbacksEmpty => 'لا توجد ذكريات حتى الآن…';

  @override
  String get flashbackGoodDay => 'يوم جيد';

  @override
  String get flashbackRandomDay => 'يوم عشوائي';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أسبوع',
      many: 'منذ $count أسبوعًا',
      few: 'منذ $count أسابيع',
      two: 'منذ أسبوعين',
      one: 'منذ أسبوع واحد',
      zero: 'منذ $count أسبوع',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أشهر',
      one: 'منذ شهر واحد',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count سنوات',
      one: 'منذ سنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'في مثل هذا اليوم';

  @override
  String get pageGalleryTitle => 'المعرض';

  @override
  String get searchLogsHint => 'ابحث في السجلات…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجلات',
      one: '$count سجل',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: '$count يوم',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count كلمات',
      one: '$count كلمة',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'لا توجد سجلات…';

  @override
  String get noResults => 'لا يوجد نتأج';

  @override
  String get sortDateTitle => 'التاريخ';

  @override
  String get sortOrderAscendingTitle => 'تصاعدي';

  @override
  String get sortOrderDescendingTitle => 'تنازلي';

  @override
  String get pageStatisticsTitle => 'إحصائيات';

  @override
  String get statisticsNotEnoughData => 'لا توجد بيانات كافية…';

  @override
  String get statisticsRangeOneMonth => 'شهر';

  @override
  String get statisticsRangeSixMonths => '٦ أشهر';

  @override
  String get statisticsRangeOneYear => 'سنة';

  @override
  String get statisticsRangeAllTime => 'كل الأوقات';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag الملخص';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag حسب اليوم';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag بمرور الوقت';
  }

  @override
  String get chartGroupingLabel => 'تجميع حسب';

  @override
  String get chartGroupingDay => 'اليوم';

  @override
  String get chartGroupingWeek => 'الأسبوع';

  @override
  String get chartGroupingMonth => 'الشهر';

  @override
  String get chartGroupingYear => 'السنة';

  @override
  String get chartSmoothingLabel => 'التنعيم';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'السلسلة الحالية $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أطول سلسلة $count',
    );
    return '$_temp0';
  }

  @override
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام عظيمة $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام منذ يوم سيء',
      one: 'يوم منذ يوم سيء',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'لا يمكن الوصول إلى وحدة التخزين الخارجية';

  @override
  String get errorExternalStorageAccessDescription =>
      'إذا كنت تستخدم التخزين عبر الانترنت تأكد من أن الخدمة متاحة ولديك وصول للشبكة.\n\nوإلا فقد يكون التطبيق فقد الأذونات للمجلد الخارجي. اذهب إلى الإعدادات وأعد اختيار المجلد الخارجي لمنح الوصول.\n\nتحذير، لن تتم مزامنة التغييرات حتى تستعيد الوصول إلى موقع التخزين الخارجي!';

  @override
  String get errorExternalStorageAccessContinue =>
      'متابعة مع قاعدة البيانات المحلية';

  @override
  String get databaseMigrationErrorTitle => 'تعذر نقل بياناتك';

  @override
  String get databaseMigrationErrorDescription =>
      'بياناتك آمنة، لكن لم يتمكن التطبيق من نقلها إلى مساحة التخزين الخاصة به.\n\nحاول مرة أخرى، وأبلغ عن المشكلة إذا استمرت في الحدوث.';

  @override
  String get databaseMigrationErrorRetry => 'عيد';

  @override
  String get errorReport => 'إبلغ عن مشكلة';

  @override
  String get lastModified => 'معدّل';

  @override
  String get writeSomethingHint => 'اكتب شيئًا…';

  @override
  String get titleHint => 'عنوان…';

  @override
  String get deleteLogTitle => 'احذف السجل';

  @override
  String get deleteLogDescription => 'هل تريد حذف هذا السجل؟';

  @override
  String get deletePhotoTitle => 'احذف الصورة';

  @override
  String get deletePhotoDescription => 'هل تريد حذف هذه الصورة؟';

  @override
  String get pageSettingsTitle => 'الإعدادات';

  @override
  String get settingsAppearanceTitle => 'المظهر';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeAmoled => 'أموليد';

  @override
  String get settingsFirstDayOfWeek => 'أول يوم في الأسبوع';

  @override
  String get settingsCalendarSystem => 'نظام التاريخ';

  @override
  String get calendarSystemGregorian => 'الميلادي';

  @override
  String get calendarSystemJalali => 'جلالي';

  @override
  String get settingsUseSystemAccentColor => 'استخدم ألوان النظام';

  @override
  String get settingsCustomAccentColor => 'لون مخصص';

  @override
  String get settingsShowMarkdownToolbar => 'إظهار شريط أدوات Markdown';

  @override
  String get settingsShowFlashbacks => 'اعرض الذكريات';

  @override
  String get settingsChangeMoodIcons => 'غيِّر شكل الأيقونات';

  @override
  String get moodIconPrompt => 'أدخل أيقونة';

  @override
  String get settingsFlashbacksViewLayout => 'طريقة عرض الذكريات';

  @override
  String get settingsGalleryViewLayout => 'طريقة عرض الصور';

  @override
  String get settingsHideImagesInGallery => 'إخفاء الصور من معرض الصور';

  @override
  String get settingsHideImages => 'إخفاء الصور';

  @override
  String get pageCalendarTitle => 'التقويم';

  @override
  String get viewLayoutList => 'قائمة';

  @override
  String get viewLayoutGrid => 'شبكة';

  @override
  String get settingsNotificationsTitle => 'الإشعارات';

  @override
  String get settingsDailyReminderOnboarding =>
      'قم بتفعيل التذكيرات اليومية لتحافظ على استمرارك!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'سيتم طلب إذن \"جدولة التنبيهات\" لإرسال التذكير في لحظة عشوائية أو في الوقت المفضل لديك.';

  @override
  String get settingsDailyReminderTitle => 'تذكير يومي';

  @override
  String get settingsOnThisDayDescription => 'استرجع الذكريات الماضية';

  @override
  String get settingsDailyReminderDescription => 'تذكير لطيف كل يوم';

  @override
  String get settingsReminderTime => 'وقت التذكير';

  @override
  String get settingsFixedReminderTimeTitle => 'وقت التذكير الثابت';

  @override
  String get settingsFixedReminderTimeDescription =>
      'اختر وقتًا ثابتًا للتذكير';

  @override
  String get settingsAlwaysSendReminderTitle => 'أرسل تذكير دائمًا';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'أرسل تذكير حتى لو تم بدء السجل بالفعل';

  @override
  String get settingsCustomizeNotificationTitle => 'تخصيص الإشعارات';

  @override
  String get settingsTemplatesTitle => 'القوالب';

  @override
  String get settingsDefaultTemplate => 'القالب الافتراضي';

  @override
  String get manageTemplates => 'إدارة القوالب';

  @override
  String get addTemplate => 'إضافة قالب';

  @override
  String get newTemplate => 'قالب جديد';

  @override
  String get noTemplateTitle => 'لا شيء';

  @override
  String get noTemplatesDescription => 'لم يتم إنشاء أي قوالب بعد…';

  @override
  String get templateVariableTime => 'الوقت';

  @override
  String get templateDefaultTimestampTitle => 'الطابع الزمني';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'ملخص اليوم';

  @override
  String get templateDefaultSummaryBody => '### ملخص\n-\n\n### اقتباس\n> ';

  @override
  String get templateDefaultReflectionTitle => 'تأمل';

  @override
  String get templateDefaultReflectionBody =>
      '### ما الذي استمتعت به اليوم؟\n- \n\n### ما الذي تشعر بالامتنان تجاهه؟\n- \n\n### ما الذي تتطلع إليه؟\n- ';

  @override
  String get settingsTagsTitle => 'العلامات';

  @override
  String get manageTags => 'إدارة العلامات';

  @override
  String get tagTypeLabelTitle => 'التسمية';

  @override
  String get tagTypeTrackerTitle => 'أداة التتبع';

  @override
  String get nameHint => 'أسم';

  @override
  String get tagColorLabel => 'لون';

  @override
  String get iconPickerTitle => 'اختار الرمز';

  @override
  String get iconPickerIconsTab => 'الرموز';

  @override
  String get iconPickerCustomTab => 'مخصص';

  @override
  String get iconPickerSearchHint => 'ابحث الرموز…';

  @override
  String get colorPickerTitle => 'اختار اللون';

  @override
  String get colorPickerPaletteTab => 'الوان';

  @override
  String get iconGroupMoodPeople => 'المزاج والناس';

  @override
  String get iconGroupHealth => 'الصحة';

  @override
  String get iconGroupWorkFinance => 'العمل';

  @override
  String get iconGroupHabitsGoals => 'Habits & Goals';

  @override
  String get iconGroupNature => 'Nature';

  @override
  String get iconGroupFoodDrink => 'Food & Drink';

  @override
  String get iconGroupHome => 'الرئيسية';

  @override
  String get iconGroupTravel => 'السفر';

  @override
  String get iconGroupSymbols => 'رموز';

  @override
  String get tagCategoryLabel => 'فئة';

  @override
  String get tagLabel => 'علامة';

  @override
  String get tagCategoryUncategorized => 'غير مصنف';

  @override
  String get newCategoryTitle => 'فئة جديدة';

  @override
  String get shareButtonLabel => 'مشاركة';

  @override
  String get importErrorDescription => 'تعذّر استيراد الملف!';

  @override
  String get exportErrorDescription => 'تعذّر تصدير الملف!';

  @override
  String get deleteTitle => 'حذف';

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
    return 'حذف \"$name\"؟';
  }

  @override
  String get filterTagsTitle => 'تصفية';

  @override
  String get tagFilterModeAny => 'اي علامة';

  @override
  String get tagFilterModeAll => 'كل العلامات';

  @override
  String get clearAllFilters => 'مسح الكل';

  @override
  String get noTagsFilterLabel => 'بدون علامات';

  @override
  String get addTagsTitle => 'إضافة علامات';

  @override
  String get addTagsSearchHint => 'البحث عن علامات…';

  @override
  String get tagPickerSortManualLabel => 'ترتيب يدوي';

  @override
  String get tagPickerSortUsageLabel => 'الترتيب حسب الاستخدام';

  @override
  String get tagFavoriteName => 'المفضلة';

  @override
  String get tagEnergyName => 'الطاقة';

  @override
  String get tagCategoryActivitiesName => 'الأنشطة';

  @override
  String get tagExerciseName => 'تمارين';

  @override
  String get tagSocializingName => 'التواصل الاجتماعي';

  @override
  String get tagHobbyName => 'هواية';

  @override
  String get tagEntertainmentName => 'الترفيه';

  @override
  String get tagDiningName => 'تناول الطعام';

  @override
  String get tagChoresName => 'الأعمال اليومية';

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
  String get settingsStorageTitle => 'التخزين';

  @override
  String get settingsImageQuality => 'جودة الصورة';

  @override
  String get imageQualityHigh => 'عالية';

  @override
  String get imageQualityMedium => 'متوسطة';

  @override
  String get imageQualityLow => 'منخفضة';

  @override
  String get imageQualityNoCompression => 'بدون ضغط';

  @override
  String get settingsLogFolder => 'مجلد السجل';

  @override
  String get settingsImageFolder => 'مجلد الصور';

  @override
  String get warningTitle => 'تحذير';

  @override
  String get logFolderWarningDescription =>
      'إذا كان المجلد المحدد يحتوي بالفعل على ملف \"daily_you.db\"، فسيتم استخدامه لاستبدال سجلاتك الحالية!';

  @override
  String get errorTitle => 'خطأ';

  @override
  String get logFolderErrorDescription => 'فشل في تغيير مجلد السجل!';

  @override
  String get imageFolderErrorDescription => 'فشل في تغيير مجلد الصور!';

  @override
  String get backupErrorDescription => 'فشل في إنشاء النسخة الاحتياطية!';

  @override
  String get restoreErrorDescription => 'فشل في استعادة النسخة الاحتياطية!';

  @override
  String get settingsBackupRestoreTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get settingsBackup => 'النسخ الاحتياطي';

  @override
  String get settingsRestore => 'الاستعادة';

  @override
  String get settingsRestorePromptDescription =>
      'إن استعادة النسخة الاحتياطية سوف يؤدي إلى استبدال بياناتك الحالية!';

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
  String get autoBackupProgressTitle => 'Backing Up…';

  @override
  String get autoBackupFailedTitle => 'Backup Failed';

  @override
  String tranferStatus(Object percent) {
    return 'جارٍ النقل… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'جارٍ إنشاء نسخة احتياطية... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'جارٍ استعادة النسخة الاحتياطية… $percent%';
  }

  @override
  String get cleanUpStatus => 'جارٍ التنظيف…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'التصدير إلى تنسيق آخر';

  @override
  String get settingsExportFormatDescription =>
      'لا ينبغي استخدام هذا كنسخة احتياطية!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'الاستيراد من تطبيق آخر';

  @override
  String get settingsTranslateCallToAction =>
      'ينبغي أن يكون لدى الجميع إمكانية الوصول إلى دفتر اليوميات!';

  @override
  String get settingsHelpTranslate => 'ساعد في الترجمة';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'اختر التنسيق';

  @override
  String get logFormatDescription =>
      'قد لا يدعم تنسيق تطبيق آخر جميع الميزات. يُرجى الإبلاغ عن أي مشاكل، إذ قد تتغير تنسيقات الجهات الخارجية في أي وقت. لن يؤثر هذا على السجلات الحالية!';

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
  String get formatMarkdown => 'ماركداون (markdown)';

  @override
  String get settingsDeleteAllLogsTitle => 'احذف جميع السجلات';

  @override
  String get settingsDeleteAllLogsDescription => 'هل تريد حذف كافة سجلاتك؟';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'أدخل \'$prompt\' للتأكيد. لا يمكن التراجع عن هذا!';
  }

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsAppLanguageTitle => 'لغة التطبيق';

  @override
  String get settingsOverrideAppLanguageTitle => 'أجبر لغة التطبيق';

  @override
  String get settingsSecurityTitle => 'الأمان';

  @override
  String get settingsSecurityRequirePassword => 'اطلب كلمة مرور';

  @override
  String get settingsSecurityEnterPassword => 'أدخل كلمة المرور';

  @override
  String get settingsSecuritySetPassword => 'تعيين كلمة المرور';

  @override
  String get settingsSecurityChangePassword => 'تغيير كلمة المرور';

  @override
  String get settingsSecurityPassword => 'كلمة المرور';

  @override
  String get settingsSecurityConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get settingsSecurityOldPassword => 'كلمة المرور القديمة';

  @override
  String get settingsSecurityIncorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get requiredPrompt => 'مطلوب';

  @override
  String get settingsSecurityBiometricUnlock =>
      'افتح باستخدام القياسات الحيوية';

  @override
  String get unlockAppPrompt => 'افتح التطبيق';

  @override
  String get settingsAboutTitle => 'عن التطبيق';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsLicense => 'الرخصة';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'الكود المصدري';

  @override
  String get settingsMadeWithLove => 'مصنوع ب ❤️';

  @override
  String get settingsConsiderSupporting => 'فكر في الدعم';

  @override
  String get imagesTitle => 'Images';

  @override
  String get tagMoodTitle => 'المزاج';

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
