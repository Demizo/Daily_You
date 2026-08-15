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
  String get actionTakePhoto => 'Prendre une photo';

  @override
  String get actionToday => 'Aujourd\'hui';

  @override
  String get actionOtherDay => 'Autre jour';

  @override
  String get pageHomeTitle => 'Accueil';

  @override
  String get jumpToMonthTitle => 'Aller au mois';

  @override
  String get jumpToLogTitle => 'Aller à l’entrée';

  @override
  String get flashbacksTitle => 'Souvenirs';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclure les mauvais jours';

  @override
  String get flaskbacksEmpty => 'Pas encore de souvenirs…';

  @override
  String get flashbackGoodDay => 'Une bonne journée';

  @override
  String get flashbackRandomDay => 'Une journée ordinaire';

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
  String get flashbackOnThisDay => 'Il y a 1 an';

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
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
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
  String get noResults => 'Aucun résultat…';

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
  String chartOverTimeTitle(Object tag) {
    return '$tag sur la durée';
  }

  @override
  String get chartGroupingLabel => 'Grouper par';

  @override
  String get chartGroupingDay => 'Jour';

  @override
  String get chartGroupingWeek => 'Semaine';

  @override
  String get chartGroupingMonth => 'Mois';

  @override
  String get chartGroupingYear => 'Année';

  @override
  String get chartSmoothingLabel => 'Lissage';

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
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bonnes journées $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours depuis une mauvaise journée $count',
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
  String get databaseMigrationErrorTitle =>
      'Déplacement des données impossible';

  @override
  String get databaseMigrationErrorDescription =>
      'Vos entrées sont en sécurité mais n\'ont pas pu être déplacées dans le stockage applicatif.\n\nEssayez de nouveau et signaler ce souci s’il continue de se produire.';

  @override
  String get databaseMigrationErrorRetry => 'Réessayer';

  @override
  String get errorReport => 'Signaler un problème';

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
  String get settingsCalendarSystem => 'Système calendaire';

  @override
  String get calendarSystemGregorian => 'Grégorien';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor =>
      'Utiliser la couleur d\'appui du système';

  @override
  String get settingsCustomAccentColor => 'Couleur d\'appui personnalisée';

  @override
  String get settingsShowMarkdownToolbar =>
      'Afficher la barre d\'outils Markdown';

  @override
  String get settingsShowFlashbacks => 'Afficher les souvenirs';

  @override
  String get settingsChangeMoodIcons => 'Modifier les icônes d\'humeur';

  @override
  String get moodIconPrompt => 'Saisir une icône';

  @override
  String get settingsFlashbacksViewLayout =>
      'Disposition de la vue des flashbacks';

  @override
  String get settingsGalleryViewLayout => 'Disposition de la galerie';

  @override
  String get settingsHideImagesInGallery => 'Cacher les images dans la galerie';

  @override
  String get settingsHideImages => 'Masquer les images';

  @override
  String get pageCalendarTitle => 'Agenda';

  @override
  String get viewLayoutList => 'Liste';

  @override
  String get viewLayoutGrid => 'Grille';

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
  String get settingsOnThisDayDescription => 'Revisiter des mémoires d\'avant';

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
  String get templateVariableTime => 'Heure';

  @override
  String get templateDefaultTimestampTitle => 'Horodatage';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date – $time :';
  }

  @override
  String get templateDefaultSummaryTitle => 'Résumé du jour';

  @override
  String get templateDefaultSummaryBody => '### Résumé\n- \n\n### Avis\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Remarque';

  @override
  String get templateDefaultReflectionBody =>
      '### Qu\'est-ce qui vous a plu aujourd\'hui ?\n- \n\n### Pour quoi avez-vous de la reconnaissance ?\n- \n\n### Qu\'est-ce qu\'il vous tarde ?\n- ';

  @override
  String get settingsTagsTitle => 'Étiquettes';

  @override
  String get manageTags => 'Gestion des étiquettes';

  @override
  String get tagTypeLabelTitle => 'Label';

  @override
  String get tagTypeTrackerTitle => 'Compteur';

  @override
  String get nameHint => 'Nom';

  @override
  String get tagColorLabel => 'Couleur';

  @override
  String get iconPickerTitle => 'Choisir une icône';

  @override
  String get iconPickerIconsTab => 'Icône';

  @override
  String get iconPickerCustomTab => 'Personnalisée';

  @override
  String get iconPickerSearchHint => 'Chercher des icônes…';

  @override
  String get colorPickerTitle => 'Choisir une couleur';

  @override
  String get colorPickerPaletteTab => 'Couleurs';

  @override
  String get iconGroupMoodPeople => 'Humeur et gens';

  @override
  String get iconGroupHealth => 'Santé';

  @override
  String get iconGroupWorkFinance => 'Travail et finance';

  @override
  String get iconGroupHabitsGoals => 'Habitudes et objectifs';

  @override
  String get iconGroupNature => 'Nature';

  @override
  String get iconGroupFoodDrink => 'Boire et manger';

  @override
  String get iconGroupHome => 'Maison';

  @override
  String get iconGroupTravel => 'Voyage';

  @override
  String get iconGroupSymbols => 'Symboles';

  @override
  String get tagCategoryLabel => 'Catégorie';

  @override
  String get tagLabel => 'Tag';

  @override
  String get tagCategoryUncategorized => 'Sans catégorie';

  @override
  String get newCategoryTitle => 'Nouvelle catégorie';

  @override
  String get shareButtonLabel => 'Share';

  @override
  String get importErrorDescription => 'Failed to import file!';

  @override
  String get exportErrorDescription => 'Failed to export file!';

  @override
  String get deleteTitle => 'Supprimer';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Il est utilisé dans $count enregistrements.',
      one: ' Il est utilisé dans 1 enregistrement.',
      zero: '',
    );
    return 'Supprimer « $name » ?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Les $count étiquettes seront aussi supprimées.',
      one: ' Son étiquette  sera aussi supprimée.',
      zero: '',
    );
    return 'Supprimer « $name » ?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get filterTagsTitle => 'Filtrer';

  @override
  String get tagFilterModeAny => 'N’importe quelle étiquette';

  @override
  String get tagFilterModeAll => 'Toutes les étiquettes';

  @override
  String get clearAllFilters => 'Tout effacer';

  @override
  String get noTagsFilterLabel => 'Aucune étiquette';

  @override
  String get addTagsTitle => 'Ajouter des étiquettes';

  @override
  String get addTagsSearchHint => 'Chercher des étiquettes…';

  @override
  String get tagPickerSortManualLabel => 'Ordre manuel';

  @override
  String get tagPickerSortUsageLabel => 'Trier par utilisation';

  @override
  String get tagFavoriteName => 'Favoris';

  @override
  String get tagEnergyName => 'Énergie';

  @override
  String get tagCategoryActivitiesName => 'Activités';

  @override
  String get tagExerciseName => 'Exercice';

  @override
  String get tagSocializingName => 'Vie sociale';

  @override
  String get tagHobbyName => 'Loisir';

  @override
  String get tagEntertainmentName => 'Divertissement';

  @override
  String get tagDiningName => 'Dîner';

  @override
  String get tagChoresName => 'Tâches ménagères';

  @override
  String get tagCategoryEmotionsName => 'Émotions';

  @override
  String get tagExcitedName => 'Impatience';

  @override
  String get tagGratefulName => 'Reconnaissance';

  @override
  String get tagCalmName => 'Calme';

  @override
  String get tagTiredName => 'Fatigue';

  @override
  String get tagAnxiousName => 'Anxiété';

  @override
  String get tagAnnoyedName => 'Ennui';

  @override
  String get welcomeLogBodyText =>
      '## Bienvenue dans Daily You\n\n> Chaque jour mérite qu\'on s\'en souvienne, immortalisez-le !\n\n**Daily You** est gratuit, [open source](https://github.com/Demizo/Daily_You) et soutenu par la communauté. Conçu avec la conviction que votre journal doit vous appartenir, et non être un produit :\n\n- Aucune publicité\n- Aucune fonctionnalité verrouillée\n- Aucun suivi ni collecte de données\n\nQue vous teniez un journal, que vous fassiez de l\'introspection ou que vous notiez simplement ce qui vous a fait sourire, **Daily You** vous offre un espace privé qui est _vraiment le vôtre_.';

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
  String migratingImagesStatus(Object current, Object total) {
    return 'Migration des photos… $current/$total';
  }

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
  String get imagesTitle => 'Images';

  @override
  String get tagMoodTitle => 'Humeur';

  @override
  String get calendarTagDisplayLabel => 'Étiquette';

  @override
  String get selectTagTitle => 'Sélectionner une étiquette';

  @override
  String get labelPresentLabel => 'Présent';

  @override
  String get labelAbsentLabel => 'Absent';

  @override
  String get labelCoverageLabel => 'Couverture';

  @override
  String chartDistributionTitle(Object tag) {
    return 'Distribution de $tag';
  }
}
