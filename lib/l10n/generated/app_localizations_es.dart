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
  String get actionTakePhoto => 'Tomar foto';

  @override
  String get actionToday => 'Hoy';

  @override
  String get actionOtherDay => 'Otro día';

  @override
  String get pageHomeTitle => 'Inicio';

  @override
  String get jumpToMonthTitle => 'Ir a mes';

  @override
  String get jumpToLogTitle => 'Ir al registro';

  @override
  String get flashbacksTitle => 'Recuerdos';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Excluir dias malos';

  @override
  String get flaskbacksEmpty => 'Aún no hay recuerdos…';

  @override
  String get flashbackGoodDay => 'Un Buen Día';

  @override
  String get flashbackRandomDay => 'Un Día Aleatorio';

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
  String get flashbackOnThisDay => 'En este día';

  @override
  String get pageGalleryTitle => 'Galería';

  @override
  String get searchLogsHint => 'Buscar registros…';

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
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palabras',
      one: '$count palabra',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'No hay registros…';

  @override
  String get noResults => 'Sin resultados…';

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
  String get statisticsRangeOneMonth => '1 mes';

  @override
  String get statisticsRangeSixMonths => '6 meses';

  @override
  String get statisticsRangeOneYear => '1 año';

  @override
  String get statisticsRangeAllTime => 'Todo el tiempo';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Resumen de $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag por día';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag a lo largo del tiempo';
  }

  @override
  String get chartGroupingLabel => 'Agrupar por';

  @override
  String get chartGroupingDay => 'Día';

  @override
  String get chartGroupingWeek => 'Semana';

  @override
  String get chartGroupingMonth => 'Mes';

  @override
  String get chartGroupingYear => 'Año';

  @override
  String get chartSmoothingLabel => 'Suavizado';

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
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Días estupendos $count',
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
      'No se puede acceder al almacenamiento externo';

  @override
  String get errorExternalStorageAccessDescription =>
      'Si estás usando almacenamiento en red, asegúrate de que el servicio esté en línea y de que tengas acceso a la red.\n\nDe lo contrario, la aplicación puede haber perdido los permisos para la carpeta externa. Ve a la configuración y vuelve a seleccionar la carpeta externa para otorgar acceso.\n\nAdvertencia: Los cambios no se sincronizarán hasta que restaures el acceso a la ubicación de almacenamiento externo.';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continuar con la base de datos local';

  @override
  String get databaseMigrationErrorTitle => 'No se pudieron mover tus datos';

  @override
  String get databaseMigrationErrorDescription =>
      'Tus entradas están a salvo, pero no se pudieron mover al almacenamiento de la aplicación.\n\nInténtalo de nuevo, y reporta el problema si continúa ocurriendo.';

  @override
  String get databaseMigrationErrorRetry => 'Volver a intentar';

  @override
  String get errorReport => 'Reportar problema';

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
  String get pageSettingsTitle => 'Configuración';

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
  String get settingsCalendarSystem => 'Calendario del Sistema';

  @override
  String get calendarSystemGregorian => 'Gregoriano';

  @override
  String get calendarSystemJalali => 'Jalalí';

  @override
  String get settingsUseSystemAccentColor => 'Usar Color de Acento del Sistema';

  @override
  String get settingsCustomAccentColor => 'Color de Acento Personalizado';

  @override
  String get settingsShowMarkdownToolbar =>
      'Mostrar Barra de Herramientas Markdown';

  @override
  String get settingsShowFlashbacks => 'Mostrar Recuerdos';

  @override
  String get settingsChangeMoodIcons => 'Cambiar Iconos de Estado de Ánimo';

  @override
  String get moodIconPrompt => 'Introduce un icono';

  @override
  String get settingsFlashbacksViewLayout => 'Vista de Recuerdos';

  @override
  String get settingsGalleryViewLayout => 'Vista de Galería';

  @override
  String get settingsHideImagesInGallery => 'Ocultar Imágenes en Galería';

  @override
  String get settingsHideImages => 'Ocultar imágenes';

  @override
  String get pageCalendarTitle => 'Calendario';

  @override
  String get viewLayoutList => 'Lista';

  @override
  String get viewLayoutGrid => 'Cuadrícula';

  @override
  String get settingsNotificationsTitle => 'Notificaciones';

  @override
  String get settingsDailyReminderOnboarding =>
      '¡Activa recordatorios diarios para mantenerte activo!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Los permisos de \"alarmas de planificacion\" seran solicitados para enviarte un recordatorio en un momento aleatorio de tu preferencia.';

  @override
  String get settingsDailyReminderTitle => 'Recordatorio diario';

  @override
  String get settingsOnThisDayDescription => 'Revive recuerdos del pasado';

  @override
  String get settingsDailyReminderDescription => 'Breve recordatorio diario';

  @override
  String get settingsReminderTime => 'Hora del Recordatorio';

  @override
  String get settingsFixedReminderTimeTitle => 'Tiempo de Recordatorio Fijo';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Elija una hora fija para el recordatorio';

  @override
  String get settingsAlwaysSendReminderTitle => 'Siempre enviar recordatorio';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Enviar recordatorio aunque ya se haya hecho un registro del dia';

  @override
  String get settingsCustomizeNotificationTitle =>
      'Personalizar notificaciones';

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
  String get templateVariableTime => 'Tiempo';

  @override
  String get templateDefaultTimestampTitle => 'Fecha y hora';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Resumen del día';

  @override
  String get templateDefaultSummaryBody => '### Resumen\n- \n\n### Cita\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Reflexión';

  @override
  String get templateDefaultReflectionBody =>
      '### ¿Qué te gustó hoy?\n- \n\n### ¿Por qué estás agradecido/a?\n- \n\n### ¿Qué estás esperando?\n- ';

  @override
  String get settingsTagsTitle => 'Etiquetas';

  @override
  String get manageTags => 'Administrar etiquetas';

  @override
  String get tagTypeLabelTitle => 'Etiqueta';

  @override
  String get tagTypeTrackerTitle => 'Monitor';

  @override
  String get nameHint => 'Nombre';

  @override
  String get tagColorLabel => 'Color';

  @override
  String get iconPickerTitle => 'Elige un icono';

  @override
  String get iconPickerIconsTab => 'Iconos';

  @override
  String get iconPickerCustomTab => 'Personalizado';

  @override
  String get iconPickerSearchHint => 'Busca iconos…';

  @override
  String get colorPickerTitle => 'Elige color';

  @override
  String get colorPickerPaletteTab => 'Colores';

  @override
  String get iconGroupMoodPeople => 'Estados de ánimo y personas';

  @override
  String get iconGroupHealth => 'Salud';

  @override
  String get iconGroupWorkFinance => 'Trabajo y finanzas';

  @override
  String get iconGroupHabitsGoals => 'Hábitos y metas';

  @override
  String get iconGroupNature => 'Naturaleza';

  @override
  String get iconGroupFoodDrink => 'Comidas y bebidas';

  @override
  String get iconGroupHome => 'Hogar';

  @override
  String get iconGroupTravel => 'Viajes';

  @override
  String get iconGroupSymbols => 'Símbolos';

  @override
  String get tagCategoryLabel => 'Categoría';

  @override
  String get tagLabel => 'Etiqueta';

  @override
  String get tagCategoryUncategorized => 'Sin categoría';

  @override
  String get newCategoryTitle => 'Nueva categoría';

  @override
  String get shareButtonLabel => 'Compartir';

  @override
  String get importErrorDescription => '¡No se pudo importar el archivo!';

  @override
  String get exportErrorDescription => '¡No se pudo exportar el archivo!';

  @override
  String get deleteTitle => 'Borrar';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Se ha usado en $count registros.',
      one: ' Se ha usado en 1 registro.',
      zero: '',
    );
    return '¿Borrar \"$name\"?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Sus $count etiquetas también serán borradas.',
      one: ' Su etiqueta también será borrada.',
      zero: '',
    );
    return '¿Borrar \"$name\"?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return '¿Borrar \"$name\"?';
  }

  @override
  String get filterTagsTitle => 'Filtro';

  @override
  String get tagFilterModeAny => 'Cualquier etiqueta';

  @override
  String get tagFilterModeAll => 'Todas las etiquetas';

  @override
  String get clearAllFilters => 'Borrar todo';

  @override
  String get noTagsFilterLabel => 'Sin etiquetas';

  @override
  String get addTagsTitle => 'Añadir etiquetas';

  @override
  String get addTagsSearchHint => 'Buscar etiquetas…';

  @override
  String get tagPickerSortManualLabel => 'Orden manual';

  @override
  String get tagPickerSortUsageLabel => 'Ordenar por uso';

  @override
  String get tagFavoriteName => 'Favorito';

  @override
  String get tagEnergyName => 'Energía';

  @override
  String get tagCategoryActivitiesName => 'Actividades';

  @override
  String get tagExerciseName => 'Ejercicio';

  @override
  String get tagSocializingName => 'Socializando';

  @override
  String get tagHobbyName => 'Aficiones';

  @override
  String get tagEntertainmentName => 'Entretenimiento';

  @override
  String get tagDiningName => 'Cenando';

  @override
  String get tagChoresName => 'Tareas';

  @override
  String get tagCategoryEmotionsName => 'Emociones';

  @override
  String get tagExcitedName => 'Emocionado/a';

  @override
  String get tagGratefulName => 'Agradecido/a';

  @override
  String get tagCalmName => 'En calma';

  @override
  String get tagTiredName => 'Cansado/a';

  @override
  String get tagAnxiousName => 'Nervioso/a';

  @override
  String get tagAnnoyedName => 'Molesto/a';

  @override
  String get welcomeLogBodyText =>
      '## Bienvenido a Daily You\n\n> Cada día merece ser recordado, ¡captúralo!\n\n**Daily You** es gratuito, [de código abierto](https://github.com/Demizo/Daily_You), y mantenido por la comunidad. Ha sido construido con la idea de que tu diario debería ser tuyo, no un producto:\n\n- No tiene anuncios\n- No tiene características de pago\n- No rastrea ni recoge tus datos\n\nYa sea que estés escribiendo en tu diario, reflexionando, o simplemente apuntando algo que te hizo sonreír, **Daily You** te ofrece un espacio privado que es _exclusivamente tuyo_.';

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
  String get backupErrorDescription => '¡Error al intentar crear un respaldo!';

  @override
  String get restoreErrorDescription => '¡Error en restaurar respaldo!';

  @override
  String get settingsBackupRestoreTitle => 'Respaldo y restauración';

  @override
  String get settingsBackup => 'Respaldo';

  @override
  String get settingsRestore => 'Restauración';

  @override
  String get settingsRestorePromptDescription =>
      '¡Restaurar un respaldo sobreescribirá tus datos existentes!';

  @override
  String get settingsBackupPasswordProtect =>
      'Proteger respaldos con contraseña';

  @override
  String get backupEncryptedTitle => 'Respaldo encriptado';

  @override
  String get backupEncryptedContent =>
      'Este respaldo está protegido por una contraseña.';

  @override
  String get settingsAutoBackup => 'Respaldos automáticos';

  @override
  String get settingsAutoBackupLocation => 'Ubicación del respaldo';

  @override
  String get settingsAutoBackupInterval => 'Frecuencia de los respaldos';

  @override
  String get settingsAutoBackupIntervalDaily => 'Diario';

  @override
  String get settingsAutoBackupIntervalWeekly => 'Semanal';

  @override
  String get settingsAutoBackupIntervalMonthly => 'Mensual';

  @override
  String get settingsAutoBackupMaxCount => 'Respaldos que conservar';

  @override
  String get settingsAutoBackupRequireCharging => 'Solo durante la carga';

  @override
  String settingsBackupLast(Object time) {
    return 'Último respaldo $time';
  }

  @override
  String get settingsBackupNever => 'Nunca se ha respaldado';

  @override
  String settingsAutoBackupNext(Object time) {
    return 'Próximo respaldo $time';
  }

  @override
  String get settingsAutoBackupKeepAll => 'Todo';

  @override
  String get autoBackupFailedTitle => 'Respaldo fallido';

  @override
  String tranferStatus(Object percent) {
    return 'Transfiriendo… $percent %';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Creando respaldo... $percent %';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Restaurando respaldo… $percent %';
  }

  @override
  String encryptingBackupStatus(Object percent) {
    return 'Cifrando respaldo… $percent %';
  }

  @override
  String decryptingBackupStatus(Object percent) {
    return 'Descifrando respaldo… $percent %';
  }

  @override
  String get cleanUpStatus => 'Limpiando…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrando fotos… $current/$total';
  }

  @override
  String get settingsExport => 'Exportar';

  @override
  String get settingsExportToAnotherFormat => 'Exportar a otro formato';

  @override
  String get settingsExportFormatDescription =>
      'Esto no debe usarse como respaldo.';

  @override
  String get exportLogs => 'Exportar Registros';

  @override
  String get exportImages => 'Exportar Imágenes';

  @override
  String get settingsImport => 'Importar';

  @override
  String get settingsImportFromAnotherApp => 'Importar de otra aplicación';

  @override
  String get settingsTranslateCallToAction =>
      '¡Todos deberían tener acceso a un diario!';

  @override
  String get settingsHelpTranslate => 'Ayuda a traducir';

  @override
  String get importLogs => 'Importar Registros';

  @override
  String get importImages => 'Importar Imágenes';

  @override
  String get logFormatTitle => 'Elija Formato';

  @override
  String get logFormatDescription =>
      'Otros formatos de aplicaciones pueden no soportar todas las caracteristicas. Por favor reporta cualquier problema, ya que los formatos de terceros pueden cambiar con el tiempo. Esto no afectara a los registros ya existentes';

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
  String get settingsDeleteAllLogsTitle => 'Eliminar Todos los Registros';

  @override
  String get settingsDeleteAllLogsDescription =>
      '¿Quieres eliminar todos tus registros?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Escribe \'$prompt\'para confirmar. ¡Esto no se puede desahacer!';
  }

  @override
  String get settingsLanguageTitle => 'Lenguaje';

  @override
  String get settingsAppLanguageTitle => 'Lenguaje de aplicacion';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Anular lenguaje de aplicacion';

  @override
  String get settingsSecurityTitle => 'Seguridad';

  @override
  String get settingsSecurityRequirePassword => 'Requiere Contraseña';

  @override
  String get settingsSecurityEnterPassword => 'Introduzca la contraseña';

  @override
  String get settingsSecuritySetPassword => 'Establecer contraseña';

  @override
  String get settingsSecurityChangePassword => 'Cambiar contraseña';

  @override
  String get settingsSecurityPassword => 'Contraseña';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmar contraseña';

  @override
  String get settingsSecurityOldPassword => 'Contraseña antigua';

  @override
  String get settingsSecurityIncorrectPassword => 'Contraseña incorrecta';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Las contraseñas no coinciden';

  @override
  String get requiredPrompt => 'Necesario';

  @override
  String get settingsSecurityBiometricUnlock => 'Desbloqueo biometrico';

  @override
  String get unlockAppPrompt => 'Desbloquea la aplicacion';

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
  String get settingsOpenSourceLicenses => 'Licencias de código abierto';

  @override
  String get settingsMadeWithLove => 'Hecho con 💚';

  @override
  String get settingsConsiderSupporting => 'Considera en apoyar';

  @override
  String get imagesTitle => 'Imágenes';

  @override
  String get tagMoodTitle => 'Ánimo';

  @override
  String get calendarTagDisplayLabel => 'Etiqueta';

  @override
  String get selectTagTitle => 'Selecciona etiqueta';

  @override
  String get labelPresentLabel => 'Presente';

  @override
  String get labelAbsentLabel => 'Ausente';

  @override
  String get labelCoverageLabel => 'Cobertura';

  @override
  String chartDistributionTitle(Object tag) {
    return 'Distribución de $tag';
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

  @override
  String get reminderDaysTitle => 'Reminder days';

  @override
  String get alwaysOpenNewLogTitle => 'Open new log on launch';

  @override
  String get alwaysOpenNewLogDescription =>
      'Automatically open the editor when starting the app';

  @override
  String get calendarStreaksTitle => 'Streaks & indicators';

  @override
  String get settingsPaletteStyle => 'Palette style';

  @override
  String get settingsAppFont => 'Font style';
}
