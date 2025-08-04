// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Log Today!';

  @override
  String get dailyReminderDescription => 'Take your daily log…';

  @override
  String get pageHomeTitle => 'Home';

  @override
  String get flashbacksTitle => 'Flashbacks';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclude bad days';

  @override
  String get flaskbacksEmpty => 'No Flashbacks Yet…';

  @override
  String get flashbackGoodDay => 'A Good Day';

  @override
  String get flashbackRandomDay => 'A Random Day';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Weeks Ago',
      one: '$count Week Ago',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Months Ago',
      one: '$count Month Ago',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Years Ago',
      one: '$count Year Ago',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Gallery';

  @override
  String get searchLogsHint => 'Search Logs…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '$count log',
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
  String get noLogs => 'No Logs…';

  @override
  String get sortDateTitle => 'Date';

  @override
  String get sortOrderAscendingTitle => 'Ascending';

  @override
  String get sortOrderDescendingTitle => 'Descending';

  @override
  String get pageStatisticsTitle => 'Statistics';

  @override
  String get statisticsNotEnoughData => 'Not enough data…';

  @override
  String get statisticsRangeOneMonth => '1 Month';

  @override
  String get statisticsRangeSixMonths => '6 Months';

  @override
  String get statisticsRangeOneYear => '1 Year';

  @override
  String get statisticsRangeAllTime => 'All Time';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Summary';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag By Day';
  }

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
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Days Since a Bad Day $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Can\'t Access External Storage';

  @override
  String get errorExternalStorageAccessDescription =>
      'If you are using network storage make sure the service is online and you have network access.\n\nOtherwise, the app may have lost permissions for the external folder. Go to settings, and reselect the external folder to grant access.\n\nWarning, changes will not be synced until you restore access to the external storage location!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continue With Local Database';

  @override
  String get lastModified => 'Modified';

  @override
  String get writeSomethingHint => 'Write something…';

  @override
  String get titleHint => 'Title…';

  @override
  String get deleteLogTitle => 'Delete Log';

  @override
  String get deleteLogDescription => 'Do you want to delete this log?';

  @override
  String get deletePhotoTitle => 'Delete Photo';

  @override
  String get deletePhotoDescription => 'Do you want to delete this photo?';

  @override
  String get pageSettingsTitle => 'Settings';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'First Day Of Week';

  @override
  String get settingsUseSystemAccentColor => 'Use System Accent Color';

  @override
  String get settingsCustomAccentColor => 'Custom Accent Color';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Show Flashbacks';

  @override
  String get settingsChangeMoodIcons => 'Change Mood Icons';

  @override
  String get moodIconPrompt => 'Enter an icon';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsDailyReminderOnboarding =>
      'Enable daily reminders to keep yourself consistent!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'The \'schedule alarms\' permission will be requested to send the reminder at a random moment or at your preferred time.';

  @override
  String get settingsDailyReminderTitle => 'Daily Reminder';

  @override
  String get settingsDailyReminderDescription => 'A gentle reminder each day';

  @override
  String get settingsReminderTime => 'Reminder Time';

  @override
  String get settingsFixedReminderTimeTitle => 'Fixed Reminder Time';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Pick a fixed time for the reminder';

  @override
  String get settingsAlwaysSendReminderTitle => 'Always Send Reminder';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Send reminder even if a log was already started';

  @override
  String get settingsCustomizeNotificationTitle => 'Customize Notifications';

  @override
  String get settingsTemplatesTitle => 'Templates';

  @override
  String get settingsDefaultTemplate => 'Default Template';

  @override
  String get manageTemplates => 'Manage Templates';

  @override
  String get addTemplate => 'Add a Template';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'None';

  @override
  String get noTemplatesDescription => 'No templates created yet…';

  @override
  String get settingsStorageTitle => 'Storage';

  @override
  String get settingsImageQuality => 'Image Quality';

  @override
  String get imageQualityHigh => 'High';

  @override
  String get imageQualityMedium => 'Medium';

  @override
  String get imageQualityLow => 'Low';

  @override
  String get imageQualityNoCompression => 'No Compression';

  @override
  String get settingsLogFolder => 'Log Folder';

  @override
  String get settingsImageFolder => 'Image Folder';

  @override
  String get warningTitle => 'Warning';

  @override
  String get logFolderWarningDescription =>
      'If the selected folder already contains a \'daily_you.db\' file, it will be used to overwrite your existing logs!';

  @override
  String get errorTitle => 'Error';

  @override
  String get logFolderErrorDescription => 'Failed to change log folder!';

  @override
  String get imageFolderErrorDescription => 'Failed to change image folder!';

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
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Export To Another Format';

  @override
  String get settingsExportFormatDescription =>
      'This should not be used as a backup!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Import From Another App';

  @override
  String get settingsTranslateCallToAction =>
      'Everyone should have access to a journal!';

  @override
  String get settingsHelpTranslate => 'Help Translate';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Choose Format';

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
  String get settingsDeleteAllLogsTitle => 'Delete All Logs';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Do you want to delete all of your logs?';

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
  String get unlockAppPrompt => 'Unlock the app';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'Licença';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Source Code';

  @override
  String get settingsMadeWithLove => 'Made with ❤️';

  @override
  String get settingsConsiderSupporting => 'consider supporting';

  @override
  String get tagMoodTitle => 'Mood';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get dailyReminderTitle => 'Registre hoje!';

  @override
  String get dailyReminderDescription => 'Faça o seu registro diário…';

  @override
  String get pageHomeTitle => 'Início';

  @override
  String get flashbacksTitle => 'Recordações';

  @override
  String get flaskbacksEmpty => 'Ainda sem recordações…';

  @override
  String get flashbackGoodDay => 'Um Bom Dia';

  @override
  String get flashbackRandomDay => 'Um Dia Aleatório';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Semanas Atrás',
      one: '$count Semana Atrás',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Meses Atrás',
      one: '$count Mês Atrás',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anos Atrás',
      one: '$count Ano Atrás',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Galeria';

  @override
  String get searchLogsHint => 'Buscar Registros…';

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
  String get noLogs => 'Sem Registros…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Ascendente';

  @override
  String get sortOrderDescendingTitle => 'Descendente';

  @override
  String get pageStatisticsTitle => 'Estatísticas';

  @override
  String get statisticsNotEnoughData => 'Sem dados suficientes…';

  @override
  String get statisticsRangeOneMonth => '1 Mês';

  @override
  String get statisticsRangeSixMonths => '6 Meses';

  @override
  String get statisticsRangeOneYear => '1 Ano';

  @override
  String get statisticsRangeAllTime => 'Todo o histórico';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Resumo de $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Por Dia';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência Atual $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência Mais Longa $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dias Desde um Dia Ruim $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Não é possível acessar armazenamento externo';

  @override
  String get errorExternalStorageAccessDescription =>
      'Se você estiver usando o armazenamento em rede, certifique-se que o serviço está online e que você tenha acesso à rede.\n\nCaso contrário, o aplicativo pode ter perdido permissões para a pasta externa. Vá em configurações e selecione novamente a pasta externa para permitir o acesso.\n\nAtenção: as modificações não serão sincronizadas até você restaurar o acesso ao local do armazenamento externo!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continuar com banco de dados local';

  @override
  String get lastModified => 'Modificado';

  @override
  String get writeSomethingHint => 'Escreva alguma coisa…';

  @override
  String get titleHint => 'Título…';

  @override
  String get deleteLogTitle => 'Apagar Registro';

  @override
  String get deleteLogDescription => 'Você quer apagar este registro?';

  @override
  String get deletePhotoTitle => 'Remover Foto';

  @override
  String get deletePhotoDescription => 'Você quer apagar esta foto?';

  @override
  String get pageSettingsTitle => 'Configurações';

  @override
  String get settingsAppearanceTitle => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Primeiro Dia da Semana';

  @override
  String get settingsUseSystemAccentColor => 'Usar Cores do Sistema';

  @override
  String get settingsCustomAccentColor => 'Cor Personalizada';

  @override
  String get settingsShowMarkdownToolbar =>
      'Mostrar Barra de Ferramentas Markdown';

  @override
  String get settingsChangeMoodIcons => 'Alterar Ícones de Humor';

  @override
  String get moodIconPrompt => 'Insira um ícone';

  @override
  String get settingsNotificationsTitle => 'Notificações';

  @override
  String get settingsDailyReminderOnboarding =>
      'Habilite lembretes diários para te deixar consistente!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'A permissão \"Agendar Alarmes\" será solicitada para mandar lembretes a um momento aleatório ou ao seu tempo preferido.';

  @override
  String get settingsDailyReminderTitle => 'Lembrete Diário';

  @override
  String get settingsDailyReminderDescription => 'Um lembrete suave cada dia';

  @override
  String get settingsReminderTime => 'Hora do Lembrete';

  @override
  String get settingsFixedReminderTimeTitle => 'Hora do Lembrete Fixa';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Escolha uma hora fixa para o lembrete';

  @override
  String get settingsAlwaysSendReminderTitle => 'Sempre mandar um lembrete';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Mandar um lembrete mesmo se um registro já foi começado';

  @override
  String get settingsCustomizeNotificationTitle => 'Customizar Notificações';

  @override
  String get settingsTemplatesTitle => 'Modelos';

  @override
  String get settingsDefaultTemplate => 'Modelo Padrão';

  @override
  String get manageTemplates => 'Gerenciar Modelos';

  @override
  String get addTemplate => 'Adicionar Modelo';

  @override
  String get newTemplate => 'Novo Modelo';

  @override
  String get noTemplateTitle => 'Nenhum';

  @override
  String get noTemplatesDescription => 'Nenhum modelo criado ainda…';

  @override
  String get settingsStorageTitle => 'Armazenamento';

  @override
  String get settingsImageQuality => 'Qualidade da Imagem';

  @override
  String get imageQualityHigh => 'Alta';

  @override
  String get imageQualityMedium => 'Média';

  @override
  String get imageQualityLow => 'Baixa';

  @override
  String get imageQualityNoCompression => 'Sem Compressão';

  @override
  String get settingsLogFolder => 'Pasta de Registros';

  @override
  String get settingsImageFolder => 'Pasta de Imagens';

  @override
  String get warningTitle => 'Aviso';

  @override
  String get logFolderWarningDescription =>
      'Se a pasta selecionada já contiver um arquivo \'daily_you.db\', ele será usado para substituir seus registros existentes!';

  @override
  String get errorTitle => 'Erro';

  @override
  String get logFolderErrorDescription =>
      'Não foi possível alterar a pasta de registros!';

  @override
  String get imageFolderErrorDescription =>
      'Não foi possível alterar a pasta de imagens!';

  @override
  String get backupErrorDescription => 'Não foi possível criar backup!';

  @override
  String get restoreErrorDescription => 'Não foi possível restaurar backup!';

  @override
  String get settingsBackupRestoreTitle => 'Backup e Restaurar';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get settingsRestorePromptDescription =>
      'Restaurar um backup irá sobrescrever os seus dados atuais!';

  @override
  String tranferStatus(Object percent) {
    return 'Transferindo… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Criando Backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Restaurando Backup… $percent%';
  }

  @override
  String get cleanUpStatus => 'Limpando…';

  @override
  String get settingsExport => 'Exportar';

  @override
  String get exportLogs => 'Exportar Registros';

  @override
  String get exportImages => 'Exportar Imagens';

  @override
  String get settingsImport => 'Importar';

  @override
  String get settingsImportFromAnotherApp => 'Importar de Outro Aplicativo';

  @override
  String get settingsTranslateCallToAction =>
      'Todos devem ter acesso a um diário!';

  @override
  String get settingsHelpTranslate => 'Ajude a Traduzir';

  @override
  String get importLogs => 'Importar Registros';

  @override
  String get importImages => 'Importar Imagens';

  @override
  String get logFormatTitle => 'Escolher Formato';

  @override
  String get logFormatDescription =>
      'O formato de outro aplicativo pode não suportar todas as funcionalidades. Isto não irá impactar os registros existentes!';

  @override
  String get settingsDeleteAllLogsTitle => 'Apagar Todos os Registros';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Você quer apagar todos os seus registros?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Digite \'$prompt\' para confirmar. Isto não pode ser desfeito!';
  }

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsLicense => 'Licença';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Código-fonte';

  @override
  String get settingsMadeWithLove => 'Feito com ❤️';

  @override
  String get settingsConsiderSupporting => 'Considere Apoiar';

  @override
  String get tagMoodTitle => 'Humor';
}
