import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/launch_intent.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaunchPage extends StatefulWidget {
  final Widget nextPage;
  const LaunchPage({super.key, required this.nextPage});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  bool isLoading = true;
  bool _initialized = false;

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
    if (await AppDatabase.instance.init()) {
      if (ImageStorage.instance.usingExternalLocation()) {
        if (await ImageStorage.instance.hasExternalLocationPermission()) {
          await _nextPage();
        }
      } else {
        await _nextPage();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future _forceLocalDatabase() async {
    await AppDatabase.instance.init(forceWithoutSync: true);
    await _nextPage();
  }

  Future<void> _nextPage() async {
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => widget.nextPage, allowSnapshotting: false));
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Scaffold(body: SizedBox())
        : Scaffold(
            extendBody: true,
            body: Center(
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .errorExternalStorageAccessTitle,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: EdgeInsets.all(
                        32.0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .errorExternalStorageAccessDescription,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton(
                        onPressed: _forceLocalDatabase,
                        child: Text(AppLocalizations.of(context)!
                            .errorExternalStorageAccessContinue)),
                  ],
                ),
              ),
            ));
  }
}
