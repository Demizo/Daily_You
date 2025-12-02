import 'package:daily_you/config_provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/images_provider.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaunchPage extends StatefulWidget {
  final Widget nextPage;
  const LaunchPage({super.key, required this.nextPage});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _storeLocalizedNotificationStrings();
    _checkDatabaseConnection();
  }

  _storeLocalizedNotificationStrings() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'dailyReminderTitle', AppLocalizations.of(context)!.dailyReminderTitle);
    await prefs.setString('dailyReminderDescription',
        AppLocalizations.of(context)!.dailyReminderDescription);
  }

  _checkDatabaseConnection() async {
    //Initialize Database
    if (await EntriesDatabase.instance.initDB()) {
      if (EntriesDatabase.instance.usingExternalImg()) {
        if (await EntriesDatabase.instance.hasImgUriPermission()) {
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

  _forceLocalDatabase() async {
    await EntriesDatabase.instance.initDB(forceWithoutSync: true);
    await _nextPage();
  }

  Future<void> _nextPage() async {
    if (await ConfigProvider.instance.get(ConfigKey.requirePassword)) {
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
    await StatsProvider.instance.updateStats();
    await ImagesProvider.instance.update();
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
