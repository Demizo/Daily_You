// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Напиши про день!';

  @override
  String get dailyReminderDescription => 'Час написати про сьогодні…';

  @override
  String get pageHomeTitle => 'Домашня';

  @override
  String get flashbacksTitle => 'Спогади';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Виключити погані дні';

  @override
  String get flaskbacksEmpty => 'Ще немає спогадів…';

  @override
  String get flashbackGoodDay => 'Хороший день';

  @override
  String get flashbackRandomDay => 'Випадковий день';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тижнів тому',
      few: '$count тижні тому',
      one: '$count тиждень тому',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count місяців тому',
      few: '$count місяці тому',
      one: '$count місяць тому',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count років тому',
      few: '$count роки тому',
      one: '$count рік тому',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Галерея';

  @override
  String get searchLogsHint => 'Шукати запис…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записів',
      few: '$count записи',
      one: '$count запис',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Немає записів…';

  @override
  String get sortDateTitle => 'За датою';

  @override
  String get sortOrderAscendingTitle => 'За зростанням';

  @override
  String get sortOrderDescendingTitle => 'За зменшенням';

  @override
  String get pageStatisticsTitle => 'Статистика';

  @override
  String get statisticsNotEnoughData => 'Недостатньо даних…';

  @override
  String get statisticsRangeOneMonth => '1 місяць';

  @override
  String get statisticsRangeSixMonths => '6 місяців';

  @override
  String get statisticsRangeOneYear => '1 рік';

  @override
  String get statisticsRangeAllTime => 'За весь час';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag зведений';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag за днем тижня';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Поточний ланцюжок: $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдовший ланцюжок: $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пройшло днів з останнього поганого дня: $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Не вдається отримати доступ до зовнішнього сховища';

  @override
  String get errorExternalStorageAccessDescription =>
      'Якщо ви використовуєте мережеве сховище, перевірте інтернет і доступ до сервісу сховища.\n\nТакож DailyYou могла втратити дозволи на доступ до зовнішньої теки. Перейдіть до налаштувань і знову виберіть зовнішню теку, щоб надати до неї доступ.\n\nУвага, зміни не будуть синхронізовані, доки ви не відновите доступ до зовнішнього сховища!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Використовувати натомість локальне сховище';

  @override
  String get lastModified => 'Востаннє змінено';

  @override
  String get writeSomethingHint => 'Щось таки написати ж треба…';

  @override
  String get titleHint => 'Назва…';

  @override
  String get deleteLogTitle => 'Видалити запис';

  @override
  String get deleteLogDescription => 'Точно хочете видалити цей запис?';

  @override
  String get deletePhotoTitle => 'Видалити фото';

  @override
  String get deletePhotoDescription => 'Все ж таки видалити це фото?';

  @override
  String get pageSettingsTitle => 'Налаштування';

  @override
  String get settingsAppearanceTitle => 'Зовнішній вигляд';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeSystem => 'Як у системі';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get themeAmoled => 'Я бачу вас цікавить пітьма (OLED)';

  @override
  String get settingsFirstDayOfWeek => 'Перший день тижня';

  @override
  String get settingsUseSystemAccentColor =>
      'Використовувати колір акценту як в системі';

  @override
  String get settingsCustomAccentColor => 'Обрати свій колір акценту';

  @override
  String get settingsShowMarkdownToolbar =>
      'Відображати панель форматування тексту';

  @override
  String get settingsShowFlashbacks => 'Показати флешбеки';

  @override
  String get settingsChangeMoodIcons => 'Змініть емоджи настроїв';

  @override
  String get moodIconPrompt => 'Введіть іконку (емоджи)';

  @override
  String get settingsFlashbacksViewLayout => 'Макет перегляду флешбеків';

  @override
  String get settingsGalleryViewLayout => 'Макет перегляду галереї';

  @override
  String get settingsHideImagesInGallery => 'Приховати зображення в галереї';

  @override
  String get viewLayoutList => 'Список';

  @override
  String get viewLayoutGrid => 'Сітка';

  @override
  String get settingsNotificationsTitle => 'Нагадування';

  @override
  String get settingsDailyReminderOnboarding =>
      'Увімкніть щоденні нагадування, щоб залишатися послідовним!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Для надсилання нагадування у випадковий момент або у вибраний вами час буде запрошено дозвіл на «запланування будильників».';

  @override
  String get settingsDailyReminderTitle => 'Кожноденне нагадування';

  @override
  String get settingsDailyReminderDescription => 'Ніжне нагадування щодня';

  @override
  String get settingsReminderTime => 'Час нагадування';

  @override
  String get settingsFixedReminderTimeTitle => 'Фіксований час нагадування';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Оберіть точний час для нагадувань';

  @override
  String get settingsAlwaysSendReminderTitle => 'Завжди надсилати нагадування';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Надсилати нагадування, навіть якщо ведення журналу вже розпочато';

  @override
  String get settingsCustomizeNotificationTitle => 'Налаштувати сповіщення';

  @override
  String get settingsTemplatesTitle => 'Шаблони';

  @override
  String get settingsDefaultTemplate => 'Шаблон за замовчуванням';

  @override
  String get manageTemplates => 'Керувати шаблонами';

  @override
  String get addTemplate => 'Додати шаблон';

  @override
  String get newTemplate => 'Новий шаблон';

  @override
  String get noTemplateTitle => 'Порожній';

  @override
  String get noTemplatesDescription => 'Жодного шаблону немає…';

  @override
  String get settingsStorageTitle => 'Сховище';

  @override
  String get settingsImageQuality => 'Якість світлин';

  @override
  String get imageQualityHigh => 'Висока';

  @override
  String get imageQualityMedium => 'Середня';

  @override
  String get imageQualityLow => 'Низька';

  @override
  String get imageQualityNoCompression => 'Оригінальна';

  @override
  String get settingsLogFolder => 'Тека для записів';

  @override
  String get settingsImageFolder => 'Тека для світлин';

  @override
  String get warningTitle => 'Увага';

  @override
  String get logFolderWarningDescription =>
      'Якщо вибрана тека вже містить файл \'daily_you.db\', він перезапише існуючі записи в журналі!';

  @override
  String get errorTitle => 'Помилка';

  @override
  String get logFolderErrorDescription =>
      'Не вдалось змінити теку для записів!';

  @override
  String get imageFolderErrorDescription =>
      'Не вдалось змінити теку для світлин!';

  @override
  String get backupErrorDescription => 'Не вдалось створити резервну копію!';

  @override
  String get restoreErrorDescription => 'Не вдалось відновити резервну копію!';

  @override
  String get settingsBackupRestoreTitle => 'Резервне копіювання та відновлення';

  @override
  String get settingsBackup => 'Резервна копія';

  @override
  String get settingsRestore => 'Відновити резервну копію';

  @override
  String get settingsRestorePromptDescription =>
      'Відновлення резервної копії перезапише всі дані!';

  @override
  String tranferStatus(Object percent) {
    return 'Обробка… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Створення резервної копії… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Відновлення із резервної копії… $percent%';
  }

  @override
  String get cleanUpStatus => 'Замітаємо сліди…';

  @override
  String get settingsExport => 'Експорт';

  @override
  String get settingsExportToAnotherFormat => 'Експорт в інший формат';

  @override
  String get settingsExportFormatDescription =>
      'Це не слід використовувати як резервний варіант!';

  @override
  String get exportLogs => 'Експортувати записи';

  @override
  String get exportImages => 'Експортувати світлини';

  @override
  String get settingsImport => 'Імпорт';

  @override
  String get settingsImportFromAnotherApp => 'Імпорт з іншої програми';

  @override
  String get settingsTranslateCallToAction =>
      'Кожен повинен мати доступ до щоденника!';

  @override
  String get settingsHelpTranslate => 'Допомога з перекладом';

  @override
  String get importLogs => 'Імпортувати записи';

  @override
  String get importImages => 'Імпортувати світлини';

  @override
  String get logFormatTitle => 'Оберіть тип файлу';

  @override
  String get logFormatDescription =>
      'Формат іншої програми може не підтримувати всі функції. Будь ласка, повідомляйте про будь-які проблеми, оскільки формати сторонніх розробників можуть змінитися будь-коли. Це не вплине на існуючі журнали!';

  @override
  String get formatDailyYouJson => 'Daily You (JSON)';

  @override
  String get formatDaybook => 'Щоденник';

  @override
  String get formatDaylio => 'Daylio';

  @override
  String get formatDiarium => 'Diarium';

  @override
  String get formatDiaro => 'Діаро';

  @override
  String get formatMyBrain => 'My Brain';

  @override
  String get formatOneShot => 'OneShot';

  @override
  String get formatPixels => 'Pixels';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => 'Видалити всі записи';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Ви дійсно хочете видалити ВСІ записи журналу?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Введіть \'$prompt\' для підтвердження. Назад шляху вже не буде!';
  }

  @override
  String get settingsLanguageTitle => 'Мова';

  @override
  String get settingsAppLanguageTitle => 'Мова програми';

  @override
  String get settingsOverrideAppLanguageTitle => 'Перевизначити мову програми';

  @override
  String get settingsSecurityTitle => 'Безпека';

  @override
  String get settingsSecurityRequirePassword => 'Вимагати пароль';

  @override
  String get settingsSecurityEnterPassword => 'Введіть пароль';

  @override
  String get settingsSecuritySetPassword => 'Встановити пароль';

  @override
  String get settingsSecurityChangePassword => 'Змінити пароль';

  @override
  String get settingsSecurityPassword => 'Пароль';

  @override
  String get settingsSecurityConfirmPassword => 'Підтвердьте пароль';

  @override
  String get settingsSecurityOldPassword => 'Старий пароль';

  @override
  String get settingsSecurityIncorrectPassword => 'Неправильний пароль';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Паролі не збігаються';

  @override
  String get requiredPrompt => 'Обов\'язково';

  @override
  String get settingsSecurityBiometricUnlock => 'Біометричне розблокування';

  @override
  String get unlockAppPrompt => 'Розблокувати додаток';

  @override
  String get settingsAboutTitle => 'Про нас';

  @override
  String get settingsVersion => 'Версія';

  @override
  String get settingsLicense => 'Ліцензія';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Вихідний код';

  @override
  String get settingsMadeWithLove => 'Зроблено з ❤️';

  @override
  String get settingsConsiderSupporting => 'розглянути можливість підтримки';

  @override
  String get tagMoodTitle => 'Настрій';
}
