// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Scrivi sul Tuo Diario!';

  @override
  String get dailyReminderDescription =>
      'Non dimenticare di tener traccia della tua giornata…';

  @override
  String get pageHomeTitle => 'Home';

  @override
  String get flashbacksTitle => 'Ricordi';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Escludi le giornate negative';

  @override
  String get flaskbacksEmpty => 'Ancora Nessun Ricordo…';

  @override
  String get flashbackGoodDay => 'Una Bella Giornata';

  @override
  String get flashbackRandomDay => 'Una Giornata a Caso';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Settimane Fa',
      one: '$count Settimana Fa',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mesi Fa',
      one: '$count Mese Fa',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anni Fa',
      one: '$count Anno Fa',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Galleria';

  @override
  String get searchLogsHint => 'Cerca Annotazioni…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count annotazioni',
      one: '$count annotazione',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parole',
      one: '$count parola',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Nessuna Annotazione…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Ascendente';

  @override
  String get sortOrderDescendingTitle => 'Discendente';

  @override
  String get pageStatisticsTitle => 'Statistiche';

  @override
  String get statisticsNotEnoughData => 'Dati insufficienti…';

  @override
  String get statisticsRangeOneMonth => '1 Mese';

  @override
  String get statisticsRangeSixMonths => '6 Mesi';

  @override
  String get statisticsRangeOneYear => '1 Anno';

  @override
  String get statisticsRangeAllTime => 'Tutto';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Riepilogo $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Giorno per Giorno';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequenza Corrente $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequenza più Lunga $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Giorni Trascorsi dall\'Ultima Giornata Negativa $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Impossibile Accedere alla Memoria Esterna';

  @override
  String get errorExternalStorageAccessDescription =>
      'Se utilizzi un archivio di rete, assicurati che il servizio sia online e che tu disponga di accesso alla rete.\n\nIn caso contrario, l\'App potrebbe aver perso le autorizzazioni per la cartella esterna. Vai alle impostazioni e riseleziona la cartella esterna per concedere l\'accesso.\n\nAttenzione, le modifiche non verranno sincronizzate finché non ripristinerai l\'accesso alla posizione di archiviazione esterna!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Prosegui col Database Locale';

  @override
  String get lastModified => 'Modificato';

  @override
  String get writeSomethingHint => 'Scrivi qualcosa…';

  @override
  String get titleHint => 'Titolo…';

  @override
  String get deleteLogTitle => 'Cancella Annotazione';

  @override
  String get deleteLogDescription =>
      'Vuoi davvero cancellare questa annotazione?';

  @override
  String get deletePhotoTitle => 'Cancella Foto';

  @override
  String get deletePhotoDescription => 'Vuoi cancellare questa foto?';

  @override
  String get pageSettingsTitle => 'Impostazioni';

  @override
  String get settingsAppearanceTitle => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Primo Giorno della Settimana';

  @override
  String get settingsUseSystemAccentColor => 'Usa Colore di Sistema';

  @override
  String get settingsCustomAccentColor => 'Colore Personalizzato';

  @override
  String get settingsShowMarkdownToolbar =>
      'Mostra la barra degli strumenti Markdown';

  @override
  String get settingsShowFlashbacks => 'Mostra Ricordi';

  @override
  String get settingsChangeMoodIcons => 'Cambia le Icone dell\'Umore';

  @override
  String get moodIconPrompt => 'Inserisci un\'icona';

  @override
  String get settingsFlashbacksViewLayout =>
      'Layout di visualizzazione Ricordi';

  @override
  String get settingsGalleryViewLayout => 'Layout visualizzazione Galleria';

  @override
  String get settingsHideImagesInGallery => 'Hide Images In Gallery';

  @override
  String get viewLayoutList => 'Elenco';

  @override
  String get viewLayoutGrid => 'Griglia';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsDailyReminderOnboarding =>
      'Attiva i promemoria giornalieri per rimanere costante!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Sarà richiesta l\'autorizzazione \'programma sveglie\' per poter inviare promemoria casuali o al momento da te preferito.';

  @override
  String get settingsDailyReminderTitle => 'Promemoria Giornaliero';

  @override
  String get settingsDailyReminderDescription =>
      'Un gentile promemoria ogni giorno';

  @override
  String get settingsReminderTime => 'Orario Promemoria';

  @override
  String get settingsFixedReminderTimeTitle => 'Orario Promemoria Fissato';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Scegli un orario fisso per il promemoria';

  @override
  String get settingsAlwaysSendReminderTitle => 'Invia Sempre Promemoria';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Invia promemoria anche se è già stata creata un\'annotazione';

  @override
  String get settingsCustomizeNotificationTitle => 'Personalizza Notifiche';

  @override
  String get settingsTemplatesTitle => 'Modelli';

  @override
  String get settingsDefaultTemplate => 'Modello Predefinito';

  @override
  String get manageTemplates => 'Gestisci Modelli';

  @override
  String get addTemplate => 'Aggiungi un Modello';

  @override
  String get newTemplate => 'Nuovo Modello';

  @override
  String get noTemplateTitle => 'Nessuno';

  @override
  String get noTemplatesDescription => 'Nessun modello ancora creato…';

  @override
  String get settingsStorageTitle => 'Memoria';

  @override
  String get settingsImageQuality => 'Qualità Immagine';

  @override
  String get imageQualityHigh => 'Alta';

  @override
  String get imageQualityMedium => 'Media';

  @override
  String get imageQualityLow => 'Bassa';

  @override
  String get imageQualityNoCompression => 'Nessuna Compressione';

  @override
  String get settingsLogFolder => 'Cartella delle Annotazioni';

  @override
  String get settingsImageFolder => 'Cartella Immagini';

  @override
  String get warningTitle => 'Attenzione';

  @override
  String get logFolderWarningDescription =>
      'Se la cartella selezionata contiene già un file \'daily_you.db\', questo verrà utilizzato per sovrascrivere le annotazioni esistenti!';

  @override
  String get errorTitle => 'Errore';

  @override
  String get logFolderErrorDescription =>
      'Impossibile cambiare cartella delle annotazioni!';

  @override
  String get imageFolderErrorDescription =>
      'Impossibile modificare la cartella delle immagini!';

  @override
  String get backupErrorDescription => 'Impossibile creare il backup!';

  @override
  String get restoreErrorDescription => 'Impossibile ripristinare il backup!';

  @override
  String get settingsBackupRestoreTitle => 'Backup & Ripristino';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'Ripristino';

  @override
  String get settingsRestorePromptDescription =>
      'Ripristinare un backup sovrascriverà i dati esistenti!';

  @override
  String tranferStatus(Object percent) {
    return 'Trasferimento… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Creazione Backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Ripristino Backup… $percent%';
  }

  @override
  String get cleanUpStatus => 'Pulizia…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Esporta in un Altro Formato';

  @override
  String get settingsExportFormatDescription =>
      'Questo non dovrebbe essere usato come backup!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importa da un\'altra App';

  @override
  String get settingsTranslateCallToAction =>
      'Chiunque dovrebbe poter tenere un diario!';

  @override
  String get settingsHelpTranslate => 'Aiuta a tradurre';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Scegli il Formato';

  @override
  String get logFormatDescription =>
      'Il formato di un\'altra App potrebbe non supportare tutte le funzionalità. Riporta qualsiasi problema riscontri poiché i formati di terze parti possono cambiare in qualsiasi momento. Ciò non avrà impatto sulle note esistenti!';

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
  String get settingsDeleteAllLogsTitle => 'Cancella Tutte le Annotazioni';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Vuoi davvero cancellare tutte le tue annotazioni?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Inserisci \'$prompt\' per confermare. Questa operazione non può essere annullata!';
  }

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsAppLanguageTitle => 'Lingua dell\'App';

  @override
  String get settingsOverrideAppLanguageTitle => 'Ridefinisci Lingua dell\'App';

  @override
  String get settingsSecurityTitle => 'Sicurezza';

  @override
  String get settingsSecurityRequirePassword => 'Richiedi Password';

  @override
  String get settingsSecurityEnterPassword => 'Inserisci Password';

  @override
  String get settingsSecuritySetPassword => 'Imposta Password';

  @override
  String get settingsSecurityChangePassword => 'Cambia Password';

  @override
  String get settingsSecurityPassword => 'Password';

  @override
  String get settingsSecurityConfirmPassword => 'Conferma Password';

  @override
  String get settingsSecurityOldPassword => 'Vecchia Password';

  @override
  String get settingsSecurityIncorrectPassword => 'Password Errata';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Le password non coincidono';

  @override
  String get requiredPrompt => 'Obbligatorio';

  @override
  String get settingsSecurityBiometricUnlock => 'Sblocco Biometrico';

  @override
  String get unlockAppPrompt => 'Sblocca l\'App';

  @override
  String get settingsAboutTitle => 'Informazioni';

  @override
  String get settingsVersion => 'Versione';

  @override
  String get settingsLicense => 'Licenza';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Codice Sorgente';

  @override
  String get settingsMadeWithLove => 'Fatto con ❤️';

  @override
  String get settingsConsiderSupporting =>
      'Considera la possibilità di sostenere il progetto';

  @override
  String get tagMoodTitle => 'Stato d\'animo';
}
