import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/launch_intent.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum _LaunchErrorType { externalAccess, migrationFailed }

class LaunchPage extends StatefulWidget {
  final Widget nextPage;
  const LaunchPage({super.key, required this.nextPage});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  final Logger _logger = Logger('LaunchPage');
  bool isLoading = true;
  bool _initialized = false;
  _LaunchErrorType _errorType = _LaunchErrorType.externalAccess;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;

      _initializeApp();
    }
  }

  Future _initializeApp() async {
    await _storeLocalizedNotificationStrings();
    await _updateAppShortcuts();
    await _checkDatabaseConnection();
  }

  Future _updateAppShortcuts() async {
    if (!Platform.isAndroid) return;
    final QuickActions quickActions = const QuickActions();
    await quickActions.initialize((shortcutType) {
      if (shortcutType == 'action_log_today') {
        DeviceInfoService().launchIntent = LaunchIntent.logToday();
      } else if (shortcutType == 'action_take_photo') {
        DeviceInfoService().launchIntent = LaunchIntent.takePhoto();
      }
    });

    await quickActions.clearShortcutItems();
    if (!mounted) return;
    await quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'action_log_today',
        localizedTitle: AppLocalizations.of(context)!.dailyReminderTitle,
        icon: '@drawable/ic_shortcut_edit',
      ),
      ShortcutItem(
        type: 'action_take_photo',
        localizedTitle: AppLocalizations.of(context)!.actionTakePhoto,
        icon: '@drawable/ic_shortcut_camera_alt',
      )
    ]);
  }

  Future _storeLocalizedNotificationStrings() async {
    var prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    await prefs.setString(
        'dailyReminderTitle', AppLocalizations.of(context)!.dailyReminderTitle);
    if (!mounted) return;
    await prefs.setString('dailyReminderDescription',
        AppLocalizations.of(context)!.dailyReminderDescription);
    if (!mounted) return;
    await prefs.setString('onThisDayNotificationTitle',
        AppLocalizations.of(context)!.flashbackOnThisDay);
    if (!mounted) return;
    await prefs.setString('onThisDayNotificationDescription',
        AppLocalizations.of(context)!.settingsOnThisDayDescription);
  }

  Future _checkDatabaseConnection() async {
    // Prompt unlock before initializing database
    if (await ConfigProvider.instance.get(ConfigKey.requirePassword)) {
      if (!mounted) return;
      await showDialog(
          context: context,
          builder: (context) => AuthPopup(
                mode: AuthPopupMode.unlock,
                title: AppLocalizations.of(context)!.unlockAppPrompt,
                showBiometrics:
                    ConfigProvider.instance.get(ConfigKey.biometricUnlock),
                dismissable: false,
                onSuccess: () {},
              ));
    }
    //Initialize Database
    bool initialized;
    try {
      initialized = await AppDatabase.instance.init();
    } catch (error, stackTrace) {
      _logger.severe('Database initialization failed', error, stackTrace);
      initialized = false;
    }

    if (initialized) {
      await _migrateImagesFromExternalStorage();
      if (ImageStorage.instance.usingExternalLocation()) {
        if (await ImageStorage.instance.hasExternalLocationPermission()) {
          await _nextPage();
          return;
        }
        _errorType = _LaunchErrorType.externalAccess;
      } else {
        await _nextPage();
        return;
      }
    } else {
      _errorType = AppDatabase.instance.migrationFailed
          ? _LaunchErrorType.migrationFailed
          : _LaunchErrorType.externalAccess;
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _retryDatabaseConnection() async {
    setState(() {
      isLoading = true;
    });
    await _checkDatabaseConnection();
  }

  Future<void> _reportIssue() async {
    await launchUrl(Uri.https("github.com", "/Demizo/Daily_You/issues"),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _migrateImagesFromExternalStorage() async {
    if (!await ImageStorage.instance.needsImageMigration()) return;
    if (!mounted) return;

    final statusNotifier = ValueNotifier<String>("");
    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    try {
      await ImageStorage.instance.migrateImagesFromExternalStorage(
        updateStatus: (migrated, total) {
          if (!mounted) return;
          statusNotifier.value = AppLocalizations.of(context)!
              .migratingImagesStatus(migrated, total);
        },
      );
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future _forceLocalDatabase() async {
    try {
      await AppDatabase.instance.init(forceWithoutSync: true);
      await _nextPage();
    } catch (error, stackTrace) {
      _logger.severe(
          'Forced local database initialization failed', error, stackTrace);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _nextPage() async {
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => widget.nextPage, allowSnapshotting: false));
  }

  Widget _buildErrorScaffold({
    required String title,
    required String description,
    required List<Widget> actions,
  }) {
    return Scaffold(
      extendBody: true,
      body: Center(
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  description,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: SizedBox());

    final localizations = AppLocalizations.of(context)!;

    switch (_errorType) {
      case _LaunchErrorType.migrationFailed:
        return _buildErrorScaffold(
          title: localizations.databaseMigrationErrorTitle,
          description: localizations.databaseMigrationErrorDescription,
          actions: [
            TextButton(
                onPressed: _retryDatabaseConnection,
                child: Text(localizations.databaseMigrationErrorRetry)),
            TextButton(
                onPressed: _reportIssue,
                child: Text(localizations.errorReport)),
          ],
        );
      case _LaunchErrorType.externalAccess:
        return _buildErrorScaffold(
          title: localizations.errorExternalStorageAccessTitle,
          description: localizations.errorExternalStorageAccessDescription,
          actions: [
            TextButton(
                onPressed: _forceLocalDatabase,
                child: Text(localizations.errorExternalStorageAccessContinue)),
          ],
        );
    }
  }
}
