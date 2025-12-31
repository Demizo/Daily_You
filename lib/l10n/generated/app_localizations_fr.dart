// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Notez votre journée !';

  @override
  String get dailyReminderDescription =>
      'N\'oubliez pas d\'enregistrer votre journée…';

  @override
  String get pageHomeTitle => 'Accueil';

  @override
  String get flashbacksTitle => 'Souvenirs';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclure les mauvais jours';

  @override
  String get flaskbacksEmpty => 'Pas encore de souvenirs…';

  @override
  String get flashbackGoodDay => 'Une bonne journée';

  @override
  String get flashbackRandomDay => 'Une journée quelconque';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '$count semaine',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '$count mois',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ans',
      one: '$count an',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Galerie';

  @override
  String get searchLogsHint => 'Rechercher des souvenirs…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements',
      one: '$count enregistrement',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots',
      one: '$count mot',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Aucun souvenir…';

  @override
  String get sortDateTitle => 'Date';

  @override
  String get sortOrderAscendingTitle => 'Ascendant';

  @override
  String get sortOrderDescendingTitle => 'Descendant';

  @override
  String get pageStatisticsTitle => 'Statistiques';

  @override
  String get statisticsNotEnoughData => 'Pas assez de données…';

  @override
  String get statisticsRangeOneMonth => '1 mois';

  @override
  String get statisticsRangeSixMonths => '6 mois';

  @override
  String get statisticsRangeOneYear => '1 an';

  @override
  String get statisticsRangeAllTime => 'Historique complet';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Résumé $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag par jour';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série actuelle $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série la plus longue $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours écoulés depuis une mauvaise journée $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Impossible d\'accéder au stockage externe';

  @override
  String get errorExternalStorageAccessDescription =>
      'Si vous utilisez le stockage en réseau, assurez-vous que le service est en ligne et que vous avez accès au réseau.\n\nDans le cas contraire, l\'application peut avoir perdu les autorisations pour le dossier externe. Allez dans les paramètres et resélectionnez le dossier externe pour lui accorder l\'accès.\n\nAttention, les modifications ne seront pas synchronisées tant que vous n\'aurez pas rétabli l\'accès à l\'emplacement de stockage externe !';

  @override
  String get errorExternalStorageAccessContinue =>
      'Poursuivre avec la base de données locale';

  @override
  String get lastModified => 'Modification';

  @override
  String get writeSomethingHint => 'Écrivez quelque chose…';

  @override
  String get titleHint => 'Titre…';

  @override
  String get deleteLogTitle => 'Supprimer le souvenir';

  @override
  String get deleteLogDescription => 'Voulez-vous supprimer ce souvenir ?';

  @override
  String get deletePhotoTitle => 'Supprimer la photo';

  @override
  String get deletePhotoDescription => 'Voulez-vous supprimer cette photo ?';

  @override
  String get pageSettingsTitle => 'Paramètres';

  @override
  String get settingsAppearanceTitle => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => '1er jour de la semaine';

  @override
  String get settingsUseSystemAccentColor =>
      'Utiliser la couleur d\'appui du système';

  @override
  String get settingsCustomAccentColor => 'Couleur d\'appui personnalisée';

  @override
  String get settingsShowMarkdownToolbar =>
      'Afficher la barre d\'outils Markdown';

  @override
  String get settingsShowFlashbacks => 'Afficher les réviviscence';

  @override
  String get settingsChangeMoodIcons => 'Modifier les icônes d\'humeur';

  @override
  String get moodIconPrompt => 'Saisir une icône';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsDailyReminderOnboarding =>
      'Activer le rappel quotidien pour être consistant !';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'On demandera l\'autorisation « alarme planifiée » pour envoyer un rappel à un moment au hasard ou au moment que vous souhaitez.';

  @override
  String get settingsDailyReminderTitle => 'Rappel quotidien';

  @override
  String get settingsDailyReminderDescription =>
      'Un simple rappel tous les jours';

  @override
  String get settingsReminderTime => 'Heure du rappel';

  @override
  String get settingsFixedReminderTimeTitle => 'Heure fixe du rappel';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Choisir une heure fixe pour le rappel';

  @override
  String get settingsAlwaysSendReminderTitle => 'Toujours envoyer un rappel';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Envoyer un rappel même une entrée est déjà commencée';

  @override
  String get settingsCustomizeNotificationTitle =>
      'Personnaliser les notifications';

  @override
  String get settingsTemplatesTitle => 'Modèles';

  @override
  String get settingsDefaultTemplate => 'Modèle par défaut';

  @override
  String get manageTemplates => 'Gérer les modèles';

  @override
  String get addTemplate => 'Ajouter un modèle';

  @override
  String get newTemplate => 'Nouveau modèle';

  @override
  String get noTemplateTitle => 'Aucun';

  @override
  String get noTemplatesDescription => 'Aucun modèle créé pour l\'instant…';

  @override
  String get settingsStorageTitle => 'Stockage';

  @override
  String get settingsImageQuality => 'Qualité d\'image';

  @override
  String get imageQualityHigh => 'Élevée';

  @override
  String get imageQualityMedium => 'Moyenne';

  @override
  String get imageQualityLow => 'Basse';

  @override
  String get imageQualityNoCompression => 'Sans compression';

  @override
  String get settingsLogFolder => 'Dossier d\'enregistrement';

  @override
  String get settingsImageFolder => 'Dossier d\'images';

  @override
  String get warningTitle => 'Attention';

  @override
  String get logFolderWarningDescription =>
      'Si le dossier sélectionné contient déjà un fichier \'daily_you.db\', celui-ci sera utilisé pour écraser vos journaux existants !';

  @override
  String get errorTitle => 'Erreur';

  @override
  String get logFolderErrorDescription =>
      'Échec de la modification du dossier d\'enregistrement !';

  @override
  String get imageFolderErrorDescription =>
      'Échec de la modification du dossier de l\'image !';

  @override
  String get backupErrorDescription =>
      'Échec de la création de la sauvegarde !';

  @override
  String get restoreErrorDescription =>
      'Échec de la restauration de la sauvegarde !';

  @override
  String get settingsBackupRestoreTitle => 'Sauvegarde et restauration';

  @override
  String get settingsBackup => 'Sauvegarde';

  @override
  String get settingsRestore => 'Restauration';

  @override
  String get settingsRestorePromptDescription =>
      'La restauration d’une sauvegarde remplacera vos données existantes !';

  @override
  String tranferStatus(Object percent) {
    return 'Transfert… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Création de la sauvegarde… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Restauration de ka sauvegarde… $percent%';
  }

  @override
  String get cleanUpStatus => 'Nettoyage…';

  @override
  String get settingsExport => 'Exporter';

  @override
  String get settingsExportToAnotherFormat => 'Exporter dans un autre format';

  @override
  String get settingsExportFormatDescription =>
      'Ne doit pas être utilisé comme sauvegarde !';

  @override
  String get exportLogs => 'Exporter les enregistrements';

  @override
  String get exportImages => 'Exporter les images';

  @override
  String get settingsImport => 'Importer';

  @override
  String get settingsImportFromAnotherApp => 'Import d’une autre application';

  @override
  String get settingsTranslateCallToAction =>
      'Tout le monde devrait avoir accès à un journal !';

  @override
  String get settingsHelpTranslate => 'Aider à traduire';

  @override
  String get importLogs => 'Importer les enregistrements';

  @override
  String get importImages => 'Importer les images';

  @override
  String get logFormatTitle => 'Choisissez le format';

  @override
  String get logFormatDescription =>
      'Le format d’un autre application peut ne pas prendre en charge toutes les fonctionnalités. Merci de signaler tout problème étant donné que les formats tiers peuvent changer avec le temps. Cela n’affectera pas les journaux existants !';

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
  String get settingsDeleteAllLogsTitle => 'Supprimer tous les enregistrements';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Voulez-vous supprimer tous vos enregistrements ?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Écrivez \'$prompt\' pour confirmer. Cette action est irréversible !';
  }

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsAppLanguageTitle => 'Ajouter une langue';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Surcharger la langue de l\'application';

  @override
  String get settingsSecurityTitle => 'Sécurité';

  @override
  String get settingsSecurityRequirePassword => 'Exiger un mot de passe';

  @override
  String get settingsSecurityEnterPassword => 'Entrer le mot de passe';

  @override
  String get settingsSecuritySetPassword => 'Définir le mot de passe';

  @override
  String get settingsSecurityChangePassword => 'Modifier le mot de passe';

  @override
  String get settingsSecurityPassword => 'Mot de passe';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get settingsSecurityOldPassword => 'Ancien mot de passe';

  @override
  String get settingsSecurityIncorrectPassword => 'Mot de passe incorrect';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Les mots de passe sont différents';

  @override
  String get requiredPrompt => 'Requis';

  @override
  String get settingsSecurityBiometricUnlock => 'Déverrouillage biométrique';

  @override
  String get unlockAppPrompt => 'Déverrouiller l\'application';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'Licence';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Code source';

  @override
  String get settingsMadeWithLove => 'Fait avec ❤️';

  @override
  String get settingsConsiderSupporting => 'pensez à soutenir';

  @override
  String get tagMoodTitle => 'Humeur';
}
