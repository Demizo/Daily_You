// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => '记得留下今日日迹！';

  @override
  String get dailyReminderDescription => '今天的日迹还没写呢…';

  @override
  String get pageHomeTitle => '主页';

  @override
  String get flashbacksTitle => '往昔重现';

  @override
  String get settingsFlashbacksExcludeBadDays => '排除糟糕的日子';

  @override
  String get flaskbacksEmpty => '暂无回忆…';

  @override
  String get flashbackGoodDay => '美好的一天';

  @override
  String get flashbackRandomDay => '随机的一天';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 周前',
      one: '$count 周前',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 月前',
      one: '$count 月前',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年前',
      one: '$count 年前',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => '迹忆';

  @override
  String get searchLogsHint => '搜索日迹…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条回忆',
      one: '$count 条回忆',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个字',
      one: '$count 个字',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => '暂无日迹…';

  @override
  String get sortDateTitle => '日期';

  @override
  String get sortOrderAscendingTitle => '升序';

  @override
  String get sortOrderDescendingTitle => '降序';

  @override
  String get pageStatisticsTitle => '统计';

  @override
  String get statisticsNotEnoughData => '数据不足…';

  @override
  String get statisticsRangeOneMonth => '1 个月';

  @override
  String get statisticsRangeSixMonths => '6 个月';

  @override
  String get statisticsRangeOneYear => '1 年';

  @override
  String get statisticsRangeAllTime => '全部';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag 概览';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag 每日分布';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已连续记录 $count 天',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最长连续记录 $count 天',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '好心情维持了 $count 天',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle => '无法访问外部存储';

  @override
  String get errorExternalStorageAccessDescription =>
      '如果您正在使用网络存储，请确保服务在线且您具有网络访问权限。\n\n否则，该应用程序可能已失去对外部文件夹的权限。请转到设置，然后重新选择外部文件夹以授予访问权限。\n\n警告，在恢复对外部存储位置的访问之前，更改将不会同步！';

  @override
  String get errorExternalStorageAccessContinue => '继续使用本地数据库';

  @override
  String get lastModified => '最后修改时间';

  @override
  String get writeSomethingHint => '写点什么…';

  @override
  String get titleHint => '标题…';

  @override
  String get deleteLogTitle => '删除日迹';

  @override
  String get deleteLogDescription => '您确定要删除该条日迹吗？';

  @override
  String get deletePhotoTitle => '删除图片';

  @override
  String get deletePhotoDescription => '您确定要删除这张图片吗？';

  @override
  String get pageSettingsTitle => '设置';

  @override
  String get settingsAppearanceTitle => '外观';

  @override
  String get settingsTheme => '主题模式';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色主题';

  @override
  String get themeDark => '深色主题';

  @override
  String get themeAmoled => '纯黑主题';

  @override
  String get settingsFirstDayOfWeek => '一周开始日';

  @override
  String get settingsUseSystemAccentColor => '使用系统强调色';

  @override
  String get settingsCustomAccentColor => '自定义强调色';

  @override
  String get settingsShowMarkdownToolbar => '显示 Markdown 工具栏';

  @override
  String get settingsShowFlashbacks => '显示往昔重现';

  @override
  String get settingsChangeMoodIcons => '更改心情图标';

  @override
  String get moodIconPrompt => '输入一个图标';

  @override
  String get settingsFlashbacksViewLayout => '往昔重现的视图布局';

  @override
  String get settingsGalleryViewLayout => '迹忆页视图布局';

  @override
  String get settingsHideImagesInGallery => '隐藏图库中的图片';

  @override
  String get viewLayoutList => '列表';

  @override
  String get viewLayoutGrid => '网格';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsDailyReminderOnboarding => '开启每日提醒，保持自己的连贯性！';

  @override
  String get settingsNotificationsPermissionsPrompt => '为了按时发送提醒，应用将请求通知权限。';

  @override
  String get settingsDailyReminderTitle => '每日提醒';

  @override
  String get settingsDailyReminderDescription => '每天一次温和的提醒';

  @override
  String get settingsReminderTime => '提醒时间';

  @override
  String get settingsFixedReminderTimeTitle => '固定提醒时间';

  @override
  String get settingsFixedReminderTimeDescription => '选择一个固定的提醒时间';

  @override
  String get settingsAlwaysSendReminderTitle => '总是发送提醒';

  @override
  String get settingsAlwaysSendReminderDescription => '即使日志已经开始，也发送提醒';

  @override
  String get settingsCustomizeNotificationTitle => '自定义通知';

  @override
  String get settingsTemplatesTitle => '模板';

  @override
  String get settingsDefaultTemplate => '默认模板';

  @override
  String get manageTemplates => '管理模板';

  @override
  String get addTemplate => '选择添加模板';

  @override
  String get newTemplate => '新建模板';

  @override
  String get noTemplateTitle => '无';

  @override
  String get noTemplatesDescription => '尚未创建任何模板…';

  @override
  String get settingsStorageTitle => '存储';

  @override
  String get settingsImageQuality => '图像质量';

  @override
  String get imageQualityHigh => '高';

  @override
  String get imageQualityMedium => '中';

  @override
  String get imageQualityLow => '低';

  @override
  String get imageQualityNoCompression => '无损';

  @override
  String get settingsLogFolder => '日迹存储目录';

  @override
  String get settingsImageFolder => '图片存储目录';

  @override
  String get warningTitle => '警告';

  @override
  String get logFolderWarningDescription =>
      '如果所选文件夹中已包含“daily_you.db”文件，它将被用于覆盖您现有的日迹！';

  @override
  String get errorTitle => '错误';

  @override
  String get logFolderErrorDescription => '无法更改日迹目录！';

  @override
  String get imageFolderErrorDescription => '无法更改图片目录！';

  @override
  String get backupErrorDescription => '创建备份失败！';

  @override
  String get restoreErrorDescription => '恢复备份失败！';

  @override
  String get settingsBackupRestoreTitle => '备份与恢复';

  @override
  String get settingsBackup => '备份数据';

  @override
  String get settingsRestore => '恢复数据';

  @override
  String get settingsRestorePromptDescription => '恢复备份将覆盖您现有的数据！';

  @override
  String tranferStatus(Object percent) {
    return '正在传输…$percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return '正在创建备份… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return '正在恢复备份…$percent%';
  }

  @override
  String get cleanUpStatus => '正在清理…';

  @override
  String get settingsExport => '导出数据';

  @override
  String get settingsExportToAnotherFormat => '导出为另一种格式';

  @override
  String get settingsExportFormatDescription => '这不应该被用作备份！';

  @override
  String get exportLogs => '导出日迹';

  @override
  String get exportImages => '导出图片';

  @override
  String get settingsImport => '导入数据';

  @override
  String get settingsImportFromAnotherApp => '从其他应用程序导入';

  @override
  String get settingsTranslateCallToAction => '每个人都应该有权使用日迹！';

  @override
  String get settingsHelpTranslate => '协助翻译';

  @override
  String get importLogs => '导入日迹';

  @override
  String get importImages => '导入图片';

  @override
  String get logFormatTitle => '选择格式';

  @override
  String get logFormatDescription =>
      '其他应用的格式可能无法支持所有功能。若遇到任何问题请及时反馈，因为第三方格式可能随时发生变化。不过这一点不会影响现有的日迹！';

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
  String get settingsDeleteAllLogsTitle => '删除全部日迹';

  @override
  String get settingsDeleteAllLogsDescription => '您确定要删除全部的日迹吗？';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return '请输入 \'$prompt\' 以确认继续删除，此操作无法撤销！';
  }

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsAppLanguageTitle => '应用程序语言';

  @override
  String get settingsOverrideAppLanguageTitle => '覆盖应用程序语言';

  @override
  String get settingsSecurityTitle => '安全';

  @override
  String get settingsSecurityRequirePassword => '使用密码解锁';

  @override
  String get settingsSecurityEnterPassword => '输入密码';

  @override
  String get settingsSecuritySetPassword => '设置密码';

  @override
  String get settingsSecurityChangePassword => '更改密码';

  @override
  String get settingsSecurityPassword => '密码';

  @override
  String get settingsSecurityConfirmPassword => '确认密码';

  @override
  String get settingsSecurityOldPassword => '旧密码';

  @override
  String get settingsSecurityIncorrectPassword => '密码错误';

  @override
  String get settingsSecurityPasswordsDoNotMatch => '密码不相符';

  @override
  String get requiredPrompt => '请输入密码';

  @override
  String get settingsSecurityBiometricUnlock => '生物识别解锁';

  @override
  String get unlockAppPrompt => '解锁应用程序';

  @override
  String get settingsAboutTitle => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLicense => '许可协议';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => '源代码';

  @override
  String get settingsMadeWithLove => '用❤️制作';

  @override
  String get settingsConsiderSupporting => '考虑支持';

  @override
  String get tagMoodTitle => '心情';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => '記錄今天！';

  @override
  String get dailyReminderDescription => '寫下我的日常紀錄…';

  @override
  String get pageHomeTitle => '主頁';

  @override
  String get flashbacksTitle => '往日重現';

  @override
  String get settingsFlashbacksExcludeBadDays => '排除糟糕的日子';

  @override
  String get flaskbacksEmpty => '暫無回憶…';

  @override
  String get flashbackGoodDay => '美好的一天';

  @override
  String get flashbackRandomDay => '隨機的一天';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 週前',
      one: '$count 週前',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 月前',
      one: '$count 月前',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年前',
      one: '$count 年前',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => '紀錄';

  @override
  String get searchLogsHint => '搜尋紀錄…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 條紀錄',
      one: '$count 條紀錄',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個字',
      one: '$count 個字',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => '無紀錄…';

  @override
  String get sortDateTitle => '日期';

  @override
  String get sortOrderAscendingTitle => '升序';

  @override
  String get sortOrderDescendingTitle => '降序';

  @override
  String get pageStatisticsTitle => '統計';

  @override
  String get statisticsNotEnoughData => '資料不足…';

  @override
  String get statisticsRangeOneMonth => '1 個月';

  @override
  String get statisticsRangeSixMonths => '6 個月';

  @override
  String get statisticsRangeOneYear => '1 年';

  @override
  String get statisticsRangeAllTime => '所有時間';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag 概覽';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag 每日分布';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '連續紀錄 $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最長連續紀錄 $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '距離上次糟糕的一天已過去 $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle => '無法存取外部儲存裝置';

  @override
  String get errorExternalStorageAccessDescription =>
      '如果您正在使用網路儲存空間，請確保服務在線且您有網路訪問的權限。\n\n否則，應用程式可能已失去對外部資料夾的權限，請前往設定並重新選擇外部資料夾以授權。\n\n警告：在恢復對外部存儲位置的訪問權限之前，任何更改將不會同步！';

  @override
  String get errorExternalStorageAccessContinue => '繼續使用本地資料庫';

  @override
  String get lastModified => '已修改';

  @override
  String get writeSomethingHint => '寫點什麼…';

  @override
  String get titleHint => '標題…';

  @override
  String get deleteLogTitle => '刪除紀錄';

  @override
  String get deleteLogDescription => '您要刪除此紀錄嗎？';

  @override
  String get deletePhotoTitle => '刪除照片';

  @override
  String get deletePhotoDescription => '您要刪除此照片嗎？';

  @override
  String get pageSettingsTitle => '設定';

  @override
  String get settingsAppearanceTitle => '外觀';

  @override
  String get settingsTheme => '主題';

  @override
  String get themeSystem => '系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get themeAmoled => '純黑';

  @override
  String get settingsFirstDayOfWeek => '一週的起始日';

  @override
  String get settingsUseSystemAccentColor => '使用系統強調色';

  @override
  String get settingsCustomAccentColor => '自訂強調色';

  @override
  String get settingsShowMarkdownToolbar => '顯示 Markdown 工具列';

  @override
  String get settingsShowFlashbacks => '顯示往日重現';

  @override
  String get settingsChangeMoodIcons => '更改心情圖示';

  @override
  String get moodIconPrompt => '輸入圖示';

  @override
  String get settingsFlashbacksViewLayout => '往日重現檢視佈局';

  @override
  String get settingsGalleryViewLayout => '紀錄檢視佈局';

  @override
  String get settingsHideImagesInGallery => '隱藏紀錄頁中的圖片';

  @override
  String get viewLayoutList => '清單';

  @override
  String get viewLayoutGrid => '網格';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsDailyReminderOnboarding => '開啟每日提醒，助你持之以恆！';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      '為了在隨機或您設定的時間發送提醒，系統將請求「排程鬧鐘」權限。';

  @override
  String get settingsDailyReminderTitle => '每日提醒';

  @override
  String get settingsDailyReminderDescription => '每日的溫馨提醒';

  @override
  String get settingsReminderTime => '提醒時間';

  @override
  String get settingsFixedReminderTimeTitle => '固定提醒時間';

  @override
  String get settingsFixedReminderTimeDescription => '選擇一個固定的時間來設置提醒';

  @override
  String get settingsAlwaysSendReminderTitle => '總是發送提醒';

  @override
  String get settingsAlwaysSendReminderDescription => '即使日記已經開始，仍需發送提醒';

  @override
  String get settingsCustomizeNotificationTitle => '自訂通知';

  @override
  String get settingsTemplatesTitle => '模板';

  @override
  String get settingsDefaultTemplate => '預設模板';

  @override
  String get manageTemplates => '管理模板';

  @override
  String get addTemplate => '新增模板';

  @override
  String get newTemplate => '新增模板';

  @override
  String get noTemplateTitle => '無';

  @override
  String get noTemplatesDescription => '尚未建立模板…';

  @override
  String get settingsStorageTitle => '存儲';

  @override
  String get settingsImageQuality => '影像品質';

  @override
  String get imageQualityHigh => '高';

  @override
  String get imageQualityMedium => '中';

  @override
  String get imageQualityLow => '低';

  @override
  String get imageQualityNoCompression => '不壓縮';

  @override
  String get settingsLogFolder => '紀錄資料夾';

  @override
  String get settingsImageFolder => '影像資料夾';

  @override
  String get warningTitle => '警告';

  @override
  String get logFolderWarningDescription =>
      '如果選定的資料夾中已經包含一個 \'daily_you.db\' 文件，它將覆蓋您現有的紀錄！';

  @override
  String get errorTitle => '錯誤';

  @override
  String get logFolderErrorDescription => '更改紀錄資料夾失敗！';

  @override
  String get imageFolderErrorDescription => '更改影像資料夾失敗！';

  @override
  String get backupErrorDescription => '備份建立失敗！';

  @override
  String get restoreErrorDescription => '備份還原失敗！';

  @override
  String get settingsBackupRestoreTitle => '備份與還原';

  @override
  String get settingsBackup => '備份';

  @override
  String get settingsRestore => '還原';

  @override
  String get settingsRestorePromptDescription => '還原備份將覆蓋您現有的資料！';

  @override
  String tranferStatus(Object percent) {
    return '正在轉移… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return '正在建立備份… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return '正在還原備份… $percent%';
  }

  @override
  String get cleanUpStatus => '正在清理…';

  @override
  String get settingsExport => '匯出';

  @override
  String get settingsExportToAnotherFormat => '匯出為其他格式';

  @override
  String get settingsExportFormatDescription => '這不應該被用來備份！';

  @override
  String get exportLogs => '匯出紀錄';

  @override
  String get exportImages => '匯出影像';

  @override
  String get settingsImport => '匯入';

  @override
  String get settingsImportFromAnotherApp => '從其他應用程式匯入';

  @override
  String get settingsTranslateCallToAction => '每個人都應該有權使用日記！';

  @override
  String get settingsHelpTranslate => '協助翻譯';

  @override
  String get importLogs => '匯入紀錄';

  @override
  String get importImages => '匯入影像';

  @override
  String get logFormatTitle => '選擇格式';

  @override
  String get logFormatDescription =>
      '其他應用程式的格式可能不支援所有功能，且第三方格式可能隨時發生變化，發現任何問題請向我們回報。這並不會影響現有日誌！';

  @override
  String get formatDiaro => 'Diaro';

  @override
  String get formatOneShot => 'OneShot';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => '刪除所有紀錄';

  @override
  String get settingsDeleteAllLogsDescription => '您要刪除所有紀錄嗎？';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return '輸入「\'$prompt\'」以確認，此操作無法撤銷！';
  }

  @override
  String get settingsLanguageTitle => '語言';

  @override
  String get settingsAppLanguageTitle => '應用程式語言';

  @override
  String get settingsOverrideAppLanguageTitle => '覆寫應用程式語言';

  @override
  String get settingsSecurityTitle => '安全';

  @override
  String get settingsSecurityRequirePassword => '使用密碼解鎖';

  @override
  String get settingsSecurityEnterPassword => '輸入密碼';

  @override
  String get settingsSecuritySetPassword => '設定密碼';

  @override
  String get settingsSecurityChangePassword => '更換密碼';

  @override
  String get settingsSecurityPassword => '密碼';

  @override
  String get settingsSecurityConfirmPassword => '確認密碼';

  @override
  String get settingsSecurityOldPassword => '舊密碼';

  @override
  String get settingsSecurityIncorrectPassword => '密碼錯誤';

  @override
  String get settingsSecurityPasswordsDoNotMatch => '密碼不相符';

  @override
  String get requiredPrompt => '必填';

  @override
  String get settingsSecurityBiometricUnlock => '生物辨識解鎖';

  @override
  String get unlockAppPrompt => '解鎖應用程式';

  @override
  String get settingsAboutTitle => '關於';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLicense => '授權';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => '原始碼';

  @override
  String get settingsMadeWithLove => '用❤️製作';

  @override
  String get settingsConsiderSupporting => '考慮支持';

  @override
  String get tagMoodTitle => '心情';
}
