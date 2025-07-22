// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => '¡Anota hoy!';

  @override
  String get dailyReminderDescription => 'Anota tu entrada diaria…';

  @override
  String get pageHomeTitle => 'Inicio';

  @override
  String get flashbacksTitle => 'Recuerdos';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclude bad days';

  @override
  String get flaskbacksEmpty => 'Aún no hay recuerdos…';

  @override
  String get flashbackGoodDay => 'Un día bueno';

  @override
  String get flashbackRandomDay => 'Un día aleatorio';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count semanas',
      one: 'Hace $count semana',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count meses',
      one: 'Hace $count mes',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count años',
      one: 'Hace $count año',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Galería';

  @override
  String get searchLogsHint => 'Buscar entradas…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '$count registro',
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
  String get noLogs => 'No hay entradas…';

  @override
  String get sortDateTitle => 'Fecha';

  @override
  String get sortOrderAscendingTitle => 'Ascendente';

  @override
  String get sortOrderDescendingTitle => 'Descendente';

  @override
  String get pageStatisticsTitle => 'Estadísticas';

  @override
  String get statisticsNotEnoughData => 'No hay suficientes datos…';

  @override
  String get statisticsRangeOneMonth => '1 Mes';

  @override
  String get statisticsRangeSixMonths => '6 Meses';

  @override
  String get statisticsRangeOneYear => '1 Año';

  @override
  String get statisticsRangeAllTime => 'Todo el tiempo';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Resumen de $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Por Día';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha actual $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha más larga $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Días desde un día malo $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'No Se Puede Acceder al Almacenamiento Externo';

  @override
  String get errorExternalStorageAccessDescription =>
      'Si estás usando almacenamiento en red, asegúrate de que el servicio esté en línea y de que tengas acceso a la red.\n\nDe lo contrario, la aplicación puede haber perdido los permisos para la carpeta externa. Ve a la configuración y vuelve a seleccionar la carpeta externa para otorgar acceso.\n\nAdvertencia: Los cambios no se sincronizarán hasta que restaures el acceso a la ubicación de almacenamiento externo.';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continuar con la base de datos local';

  @override
  String get lastModified => 'Modificado';

  @override
  String get writeSomethingHint => 'Escribe algo…';

  @override
  String get titleHint => 'Título…';

  @override
  String get deleteLogTitle => 'Eliminar entrada';

  @override
  String get deleteLogDescription => '¿Quieres eliminar esta entrada?';

  @override
  String get deletePhotoTitle => 'Eliminar foto';

  @override
  String get deletePhotoDescription => '¿Quieres eliminar esta foto?';

  @override
  String get pageSettingsTitle => 'Ajustes';

  @override
  String get settingsAppearanceTitle => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Primer Día de la Semana';

  @override
  String get settingsUseSystemAccentColor => 'Usar Color de Acento del Sistema';

  @override
  String get settingsCustomAccentColor => 'Color de Acento Personalizado';

  @override
  String get settingsShowMarkdownToolbar =>
      'Mostrar Barra de Herramientas Markdown';

  @override
  String get settingsShowFlashbacks => 'Show Flashbacks';

  @override
  String get settingsChangeMoodIcons => 'Cambiar Iconos de Estado de Ánimo';

  @override
  String get moodIconPrompt => 'Introduce un icono';

  @override
  String get settingsNotificationsTitle => 'Notificaciones';

  @override
  String get settingsDailyReminderOnboarding =>
      'Enable daily reminders to keep yourself consistent!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'The \'schedule alarms\' permission will be requested to send the reminder at a random moment or at your preferred time.';

  @override
  String get settingsDailyReminderTitle => 'Recordatorio diario';

  @override
  String get settingsDailyReminderDescription =>
      'Permitir que la aplicación se ejecute en segundo plano para obtener mejores resultados';

  @override
  String get settingsReminderTime => 'Hora del Recordatorio';

  @override
  String get settingsFixedReminderTimeTitle => 'Tiempo de Recordatorio Fijo';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Elija una hora fija para el recordatorio';

  @override
  String get settingsAlwaysSendReminderTitle => 'Always Send Reminder';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Send reminder even if a log was already started';

  @override
  String get settingsCustomizeNotificationTitle => 'Customize Notifications';

  @override
  String get settingsTemplatesTitle => 'Plantillas';

  @override
  String get settingsDefaultTemplate => 'Plantilla Predeterminada';

  @override
  String get manageTemplates => 'Administrar Plantillas';

  @override
  String get addTemplate => 'Agregar una Plantilla';

  @override
  String get newTemplate => 'Nueva Plantilla';

  @override
  String get noTemplateTitle => 'Ninguno';

  @override
  String get noTemplatesDescription => 'Aún no se han creado plantillas…';

  @override
  String get settingsStorageTitle => 'Almacenamiento';

  @override
  String get settingsImageQuality => 'Calidad de Imagen';

  @override
  String get imageQualityHigh => 'Alta';

  @override
  String get imageQualityMedium => 'Media';

  @override
  String get imageQualityLow => 'Baja';

  @override
  String get imageQualityNoCompression => 'Sin Compresión';

  @override
  String get settingsLogFolder => 'Carpeta de entradas';

  @override
  String get settingsImageFolder => 'Carpeta de Imágenes';

  @override
  String get warningTitle => 'Advertencia';

  @override
  String get logFolderWarningDescription =>
      'Si la carpeta seleccionada ya contiene un archivo \'daily_you.db\', se usará para sobrescribir tus entradas existentes!';

  @override
  String get errorTitle => 'Error';

  @override
  String get logFolderErrorDescription =>
      '¡No se pudo cambiar la carpeta de registro!';

  @override
  String get imageFolderErrorDescription =>
      '¡No se pudo cambiar la carpeta de imágenes!';

  @override
  String get backupErrorDescription => 'Failed to create backup!';

  @override
  String get restoreErrorDescription => 'Failed to restore backup!';

  @override
  String get settingsBackupRestoreTitle => 'Backup & Restore';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get settingsRestorePromptDescription =>
      'Restoring a backup will overwrite your existing data!';

  @override
  String tranferStatus(Object percent) {
    return 'Transferring… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Creating Backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Restoring Backup… $percent%';
  }

  @override
  String get cleanUpStatus => 'Cleaning Up…';

  @override
  String get settingsExport => 'Exportar';

  @override
  String get settingsExportToAnotherFormat => 'Export To Another Format';

  @override
  String get settingsExportFormatDescription =>
      'This should not be used as a backup!';

  @override
  String get exportLogs => 'Exportar Registros';

  @override
  String get exportImages => 'Exportar Imágenes';

  @override
  String get settingsImport => 'Importar';

  @override
  String get settingsImportFromAnotherApp => 'Import From Another App';

  @override
  String get settingsTranslateCallToAction =>
      'Everyone should have access to a journal!';

  @override
  String get settingsHelpTranslate => 'Help Translate';

  @override
  String get importLogs => 'Importar Registros';

  @override
  String get importImages => 'Importar Imágenes';

  @override
  String get logFormatTitle => 'Elija Formato';

  @override
  String get logFormatDescription =>
      'Another app\'s format may not support all features. Please report any issues since third party formats may change at any time. This will not impact existing logs!';

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
  String get settingsDeleteAllLogsTitle => 'Eliminar Todos los Registros';

  @override
  String get settingsDeleteAllLogsDescription =>
      '¿Quieres eliminar todos tus registros?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Enter \'$prompt\' to confirm. This cannot be undone!';
  }

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsAppLanguageTitle => 'App Language';

  @override
  String get settingsOverrideAppLanguageTitle => 'Override App Language';

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsLicense => 'Licencia';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Código Fuente';

  @override
  String get settingsMadeWithLove => 'Made with ❤️';

  @override
  String get settingsConsiderSupporting => 'consider supporting';

  @override
  String get tagMoodTitle => 'Ánimo';
}
