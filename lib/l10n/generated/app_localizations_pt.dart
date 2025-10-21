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
  String get dailyReminderTitle => 'Registe hoje!';

  @override
  String get dailyReminderDescription => 'Faça o seu registo diário…';

  @override
  String get pageHomeTitle => 'Início';

  @override
  String get flashbacksTitle => 'Recordações';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Excluir dias maus';

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
  String get searchLogsHint => 'Procurar registos…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registos',
      one: '$count registo',
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
  String get noLogs => 'Sem Registos…';

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
      'Não é possível aceder armazenamento externo';

  @override
  String get errorExternalStorageAccessDescription =>
      'Se usar o armazenamento em rede, certifique-se que o serviço está online e que tenha acesso à rede.\n\nCaso contrário, a app pode ter perdido permissões para a pasta externa. Vá em configurações e selecione novamente a pasta externa para permitir o acesso.\n\nAtenção: as modificações não serão sincronizadas até restaurar o acesso ao local do armazenamento externo!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continuar com a base de dados local';

  @override
  String get lastModified => 'Modificado';

  @override
  String get writeSomethingHint => 'Escreva alguma coisa…';

  @override
  String get titleHint => 'Título…';

  @override
  String get deleteLogTitle => 'Apagar Registo';

  @override
  String get deleteLogDescription => 'Quer apagar este registo?';

  @override
  String get deletePhotoTitle => 'Remover Foto';

  @override
  String get deletePhotoDescription => 'Quer apagar esta foto?';

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
  String get settingsShowFlashbacks => 'Mostrar recordações';

  @override
  String get settingsChangeMoodIcons => 'Alterar Ícones de Humor';

  @override
  String get moodIconPrompt => 'Insira um ícone';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'Notificações';

  @override
  String get settingsDailyReminderOnboarding =>
      'Ativar lembretes diários para deixá-lo consistente!';

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
      'Mandar um lembrete mesmo se um registo já foi começado';

  @override
  String get settingsCustomizeNotificationTitle => 'Customizar Notificações';

  @override
  String get settingsTemplatesTitle => 'Modelos';

  @override
  String get settingsDefaultTemplate => 'Modelo Padrão';

  @override
  String get manageTemplates => 'Gerir Modelos';

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
  String get settingsLogFolder => 'Pasta de Registos';

  @override
  String get settingsImageFolder => 'Pasta de Imagens';

  @override
  String get warningTitle => 'Aviso';

  @override
  String get logFolderWarningDescription =>
      'Se a pasta selecionada já contiver um ficheiro \'daily_you.db\', ele será usado para substituir os seus registos existentes!';

  @override
  String get errorTitle => 'Erro';

  @override
  String get logFolderErrorDescription =>
      'Não foi possível alterar a pasta de registos!';

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
    return 'A transferir… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'A criar um backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'A restaurar o backup… $percent%';
  }

  @override
  String get cleanUpStatus => 'A limpar…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Exportar para outro formato';

  @override
  String get settingsExportFormatDescription =>
      'Isto não deve ser usado como backup!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importar de outra app';

  @override
  String get settingsTranslateCallToAction =>
      'Todos devem ter acesso a um diário!';

  @override
  String get settingsHelpTranslate => 'Ajude a Traduzir';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Escolher Formato';

  @override
  String get logFormatDescription =>
      'O formato de outra app pode não suportar todas as funcionalidades. Por favor, informe quaisquer problemas, pois os formatos de terceiros podem mudar a qualquer momento. Isto não irá impactar os registos existentes!';

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
  String get settingsDeleteAllLogsTitle => 'Apagar Todos os Registos';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Quer apagar todos os seus registos?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Digite \'$prompt\' para confirmar. Isto não pode ser desfeito!';
  }

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsAppLanguageTitle => 'Idioma da app';

  @override
  String get settingsOverrideAppLanguageTitle => 'Substituir língua da app';

  @override
  String get settingsSecurityTitle => 'Segurança';

  @override
  String get settingsSecurityRequirePassword => 'Pedir Password';

  @override
  String get settingsSecurityEnterPassword => 'Introduza Password';

  @override
  String get settingsSecuritySetPassword => 'Definir Password';

  @override
  String get settingsSecurityChangePassword => 'Alterar Password';

  @override
  String get settingsSecurityPassword => 'Password';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmar Password';

  @override
  String get settingsSecurityOldPassword => 'Antiga Password';

  @override
  String get settingsSecurityIncorrectPassword => 'Password Incorreta';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'As passwords não são iguais';

  @override
  String get requiredPrompt => 'Requirido';

  @override
  String get settingsSecurityBiometricUnlock => 'Desbloqueio por Biometria';

  @override
  String get unlockAppPrompt => 'Desbloquear a aplicação';

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
  String get settingsFlashbacksExcludeBadDays => 'Excluir dias ruins';

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
  String get settingsShowFlashbacks => 'Mostrar Flashbacks';

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
  String get settingsExportToAnotherFormat => 'Exportar Para Outro Formato';

  @override
  String get settingsExportFormatDescription =>
      'Isso não deve ser usado como backup!';

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
      'O formato de outro aplicativo pode não suportar todas as funcionalidades. Por favor, informe qualquer problemas, pois os formatos de terceiros podem mudar a qualquer momento. Isto não irá impactar os registros existentes!';

  @override
  String get formatMarkdown => 'Markdown';

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
  String get settingsAppLanguageTitle => 'Linguagem do Aplicativo';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Substituir Linguagem do Aplicativo';

  @override
  String get settingsSecurityTitle => 'Segurança';

  @override
  String get settingsSecurityRequirePassword => 'Requer Senha';

  @override
  String get settingsSecurityEnterPassword => 'Digite a Senha';

  @override
  String get settingsSecuritySetPassword => 'Definir Senha';

  @override
  String get settingsSecurityChangePassword => 'Mudar Senha';

  @override
  String get settingsSecurityPassword => 'Senha';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmar Senha';

  @override
  String get settingsSecurityOldPassword => 'Senha Antiga';

  @override
  String get settingsSecurityIncorrectPassword => 'Senha Incorreta';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Senhas Não Correspondem';

  @override
  String get requiredPrompt => 'Obrigatório';

  @override
  String get settingsSecurityBiometricUnlock => 'Desbloquear com Biometria';

  @override
  String get unlockAppPrompt => 'Desbloquear Aplicativo';

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
