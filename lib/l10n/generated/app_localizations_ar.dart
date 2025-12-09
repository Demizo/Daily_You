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
  String get pageHomeTitle => 'الرئيسية';

  @override
  String get flashbacksTitle => 'الذكريات';

  @override
  String get settingsFlashbacksExcludeBadDays => 'استبعاد الأيام السيئة';

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
  String get pageGalleryTitle => 'المعرض';

  @override
  String get searchLogsHint => 'سجلات البحث…';

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
  String get noLogs => 'لا سجلات…';

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
  String get statisticsRangeOneMonth => '1 شهر';

  @override
  String get statisticsRangeSixMonths => '6 أشهر';

  @override
  String get statisticsRangeOneYear => '1 سنة';

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
      'إذا كنت تستخدم التخزين عبر الانترنت تأكد من أن الخدمة متاحة ولديك وصول للشبكة.\n\nوإلا فقد يكون التطبيق قد فقد الأذونات للمجلد الخارجي. اذهب إلى الإعدادات وأعد اختيار المجلد الخارجي لمنح الوصول.\n\nتحذير، لن تتم مزامنة التغييرات حتى تستعيد الوصول إلى موقع التخزين الخارجي!';

  @override
  String get errorExternalStorageAccessContinue =>
      'متابعة مع قاعدة البيانات المحلية';

  @override
  String get lastModified => 'معدل';

  @override
  String get writeSomethingHint => 'أكتب شيئا…';

  @override
  String get titleHint => 'عنوان…';

  @override
  String get deleteLogTitle => 'حذف السجل';

  @override
  String get deleteLogDescription => 'هل تريد حذف هذا السجل؟';

  @override
  String get deletePhotoTitle => 'حذف الصورة';

  @override
  String get deletePhotoDescription => 'هل تريد حذف هذه الصورة؟';

  @override
  String get pageSettingsTitle => 'إعدادات';

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
  String get settingsUseSystemAccentColor => 'استخدم الوان النظام';

  @override
  String get settingsCustomAccentColor => 'لون مميز مخصص';

  @override
  String get settingsShowMarkdownToolbar => 'إظهار شريط أدوات Markdown';

  @override
  String get settingsShowFlashbacks => 'عرض الذكريات';

  @override
  String get settingsChangeMoodIcons => 'غير وضع الايقونات';

  @override
  String get moodIconPrompt => 'أدخل ايقونة';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'التنبيهات';

  @override
  String get settingsDailyReminderOnboarding =>
      'قم بتفعيل التذكيرات اليومية لتحافظ على اتساقك!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'سيتم طلب إذن \"جدولة التنبيهات\" لإرسال التذكير في لحظة عشوائية أو في الوقت المفضل لديك.';

  @override
  String get settingsDailyReminderTitle => 'تذكير يومي';

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
  String get settingsAlwaysSendReminderTitle => 'إرسال تذكير دائمًا';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'إرسال تذكير حتى لو تم بدء السجل بالفعل';

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
  String get noTemplateTitle => 'لا شئ';

  @override
  String get noTemplatesDescription => 'لم يتم إنشاء أي قوالب بعد…';

  @override
  String get settingsStorageTitle => 'التخزين';

  @override
  String get settingsImageQuality => 'جودة الصورة';

  @override
  String get imageQualityHigh => 'عالية';

  @override
  String get imageQualityMedium => 'متوسطة';

  @override
  String get imageQualityLow => 'ضعيفة';

  @override
  String get imageQualityNoCompression => 'لا ضغط';

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
  String get imageFolderErrorDescription => 'فشل في تغيير مجلد الصورة!';

  @override
  String get backupErrorDescription => 'فشل إنشاء النسخة الاحتياطية!';

  @override
  String get restoreErrorDescription => 'فشل في استعادة النسخة الاحتياطية!';

  @override
  String get settingsBackupRestoreTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get settingsBackup => 'النسخ الاحتياطي';

  @override
  String get settingsRestore => 'الإستعادة';

  @override
  String get settingsRestorePromptDescription =>
      'إن استعادة النسخة الاحتياطية سوف يؤدي إلى استبدال بياناتك الحالية!';

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
    return 'جاري استعادة النسخة الاحتياطية… $percent%';
  }

  @override
  String get cleanUpStatus => 'جاري التنظيف…';

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
      'ينبغي أن يكون لدى الجميع إمكانية الوصول إلى المجلة!';

  @override
  String get settingsHelpTranslate => 'مساعدة في الترجمة';

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
  String get formatMarkdown => 'ماركداون';

  @override
  String get settingsDeleteAllLogsTitle => 'حذف جميع السجلات';

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
  String get settingsSecurityRequirePassword => 'طلب كلمة مرور';

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
  String get settingsSecurityBiometricUnlock => 'فتح باستخدام القياسات الحيوية';

  @override
  String get unlockAppPrompt => 'فتح التطبيق';

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
  String get tagMoodTitle => 'المزاج';
}
