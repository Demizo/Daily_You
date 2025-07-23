// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Напиши про день!';

  @override
  String get dailyReminderDescription => 'Время описать сегодня…';

  @override
  String get pageHomeTitle => 'Дом';

  @override
  String get flashbacksTitle => 'Воспоминания';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclude bad days';

  @override
  String get flaskbacksEmpty => 'Воспоминаний пока нет…';

  @override
  String get flashbackGoodDay => 'Хороший день';

  @override
  String get flashbackRandomDay => 'Случайный день';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Недель назад',
      few: '$count Недели назад',
      one: '$count Неделя назад',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Месяцев назад',
      few: '$count Месяца назад',
      one: '$count Месяц назад',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Лет назад',
      few: '$count Года назад',
      one: '$count Год назад',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Галерея';

  @override
  String get searchLogsHint => 'Искать записи…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '$count word',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Нет записей…';

  @override
  String get sortDateTitle => 'Дата';

  @override
  String get sortOrderAscendingTitle => 'Возрастание';

  @override
  String get sortOrderDescendingTitle => 'Убывание';

  @override
  String get pageStatisticsTitle => 'Статистика';

  @override
  String get statisticsNotEnoughData => 'Недостаточно данных…';

  @override
  String get statisticsRangeOneMonth => '1 Месяц';

  @override
  String get statisticsRangeSixMonths => '6 Месяцев';

  @override
  String get statisticsRangeOneYear => '1 Год';

  @override
  String get statisticsRangeAllTime => 'Все время';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Сводка';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag По дням';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Дней подряд $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Макс. дней подряд $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Дни с последнего Плохого Дня $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Нет доступа к внешнему хранилищу';

  @override
  String get errorExternalStorageAccessDescription =>
      'Если вы используете сетевое хранилище, убедитесь, что оно работает и у вас есть доступ к Интернету.\n\nВ противном случае, приложение могло потерять разрешение для доступа к внешней папке. Откройте настройки и выберите внешнюю папку снова, чтобы предоставить доступ.\n\nВнимание, изменения не будут синхронизироваться, пока доступ к внешнему хранилищу не будет восстановлен!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Продолжить с локальным хранением данных';

  @override
  String get lastModified => 'Изменено';

  @override
  String get writeSomethingHint => 'Напишите что-нибудь…';

  @override
  String get titleHint => 'Название…';

  @override
  String get deleteLogTitle => 'Удалить запись';

  @override
  String get deleteLogDescription => 'Вы хотите удалить эту запись?';

  @override
  String get deletePhotoTitle => 'Удалить фото';

  @override
  String get deletePhotoDescription => 'Вы хотите удалить это фото?';

  @override
  String get pageSettingsTitle => 'Настройки';

  @override
  String get settingsAppearanceTitle => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeSystem => 'Система';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Темная';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Первый день недели';

  @override
  String get settingsUseSystemAccentColor =>
      'Использовать акцентный цвет как в системе';

  @override
  String get settingsCustomAccentColor => 'Пользовательский акцентный цвет';

  @override
  String get settingsShowMarkdownToolbar =>
      'Показать панель инструментов Markdown';

  @override
  String get settingsShowFlashbacks => 'Show Flashbacks';

  @override
  String get settingsChangeMoodIcons => 'Изменить значки настроения';

  @override
  String get moodIconPrompt => 'Введите значок (емодзи)';

  @override
  String get settingsNotificationsTitle => 'Уведомления';

  @override
  String get settingsDailyReminderOnboarding =>
      'Enable daily reminders to keep yourself consistent!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'The \'schedule alarms\' permission will be requested to send the reminder at a random moment or at your preferred time.';

  @override
  String get settingsDailyReminderTitle => 'Ежедневное напоминание';

  @override
  String get settingsDailyReminderDescription =>
      'Разрешите приложению работать в фоне для максимального удобства';

  @override
  String get settingsReminderTime => 'Время напоминания';

  @override
  String get settingsFixedReminderTimeTitle =>
      'Фиксированное время напоминания';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Выберите фиксированное время напоминания';

  @override
  String get settingsAlwaysSendReminderTitle => 'Всегда напоминать';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Напоминать, даже если запись уже начата';

  @override
  String get settingsCustomizeNotificationTitle => 'Настроить уведомления';

  @override
  String get settingsTemplatesTitle => 'Шаблоны';

  @override
  String get settingsDefaultTemplate => 'Шаблон по умолчанию';

  @override
  String get manageTemplates => 'Управление шаблонами';

  @override
  String get addTemplate => 'Добавить шаблон';

  @override
  String get newTemplate => 'Новый шаблон';

  @override
  String get noTemplateTitle => 'Нет';

  @override
  String get noTemplatesDescription => 'Нет созданных шаблонов…';

  @override
  String get settingsStorageTitle => 'Хранилище';

  @override
  String get settingsImageQuality => 'Качество изображения';

  @override
  String get imageQualityHigh => 'Высокое';

  @override
  String get imageQualityMedium => 'Среднее';

  @override
  String get imageQualityLow => 'Низкое';

  @override
  String get imageQualityNoCompression => 'Без сжатия';

  @override
  String get settingsLogFolder => 'Папка для записей';

  @override
  String get settingsImageFolder => 'Папка для картинок';

  @override
  String get warningTitle => 'Внимание';

  @override
  String get logFolderWarningDescription =>
      'Если выбранная папка уже содержит файл \'daily_you.db\', существующие записи будут перезаписаны!';

  @override
  String get errorTitle => 'Ошибка';

  @override
  String get logFolderErrorDescription =>
      'Не удалось поменять папку для записей!';

  @override
  String get imageFolderErrorDescription =>
      'Не удалось поменять папку для картинок!';

  @override
  String get backupErrorDescription => 'Не удалось создать резервную копию!';

  @override
  String get restoreErrorDescription =>
      'Не удалось восстановить резервную копию!';

  @override
  String get settingsBackupRestoreTitle => 'Резервная копия и востановление';

  @override
  String get settingsBackup => 'Резервная копия';

  @override
  String get settingsRestore => 'Восстановить';

  @override
  String get settingsRestorePromptDescription =>
      'Откат к резервной копии перезапишет существующие данные!';

  @override
  String tranferStatus(Object percent) {
    return 'Перемещение... $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Создание резервной копии...$percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Откат из резервной копии... $percent%';
  }

  @override
  String get cleanUpStatus => 'Прибираемся…';

  @override
  String get settingsExport => 'Экспорт';

  @override
  String get settingsExportToAnotherFormat => 'Export To Another Format';

  @override
  String get settingsExportFormatDescription =>
      'This should not be used as a backup!';

  @override
  String get exportLogs => 'Экспорт записей';

  @override
  String get exportImages => 'Экспорт изображений';

  @override
  String get settingsImport => 'Импорт';

  @override
  String get settingsImportFromAnotherApp => 'Импорт из другого приложения';

  @override
  String get settingsTranslateCallToAction => 'Каждому нужен журнал!';

  @override
  String get settingsHelpTranslate => 'Помогите с переводом';

  @override
  String get importLogs => 'Импорт записей';

  @override
  String get importImages => 'Импорт изображений';

  @override
  String get logFormatTitle => 'Выбрать формат';

  @override
  String get logFormatDescription =>
      'Некоторые функции могут не поддерживаться форматом другого приложения. Но это не повлияет на существующие записи!';

  @override
  String get formatDailyYouJson => 'Daily You (JSON)';

  @override
  String get formatDaylio => 'Daylio';

  @override
  String get formatDiarium => 'Diarium';

  @override
  String get formatMyBrain => 'My Brain';

  @override
  String get formatOneShot => 'OneShot';

  @override
  String get formatPixels => 'Pixels';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => 'Удалить все записи';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Вы уверены, что хотите удалить все свои записи?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Введите \'$prompt\', чтобы подтвердить. Это действие безвозвратно!';
  }

  @override
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsAppLanguageTitle => 'App Language';

  @override
  String get settingsOverrideAppLanguageTitle => 'Override App Language';

  @override
  String get settingsSecurityTitle => 'Security';

  @override
  String get settingsSecurityUsePassword => 'Use Password';

  @override
  String get settingsSecuritySetPassword => 'Set Password';

  @override
  String get settingsSecurityPassword => 'Password';

  @override
  String get settingsSecurityConfirmPassword => 'Confirm Password';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometric Unlock';

  @override
  String get settingsAboutTitle => 'О программе';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsLicense => 'Лицензия';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Исходный код';

  @override
  String get settingsMadeWithLove => 'Сделано с ❤️';

  @override
  String get settingsConsiderSupporting => 'подумайте о поддержке проекта';

  @override
  String get tagMoodTitle => 'Настроение';
}
