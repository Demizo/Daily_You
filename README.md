<p align="center">
<img width="200" src="https://github.com/Demizo/Daily_You/blob/master/assets/logo.svg" alt="Daily You Logo">
</p>
<h1 align="center">Daily You</h1>
<h2 align="center">Every day is worth remembering...</h2>

Daily You is an app made to store memories of the passing days. Log every day and look back on past memories. All logs and photos are stored locally (the app has no internet access) and can be set to custom storage locations. Daily You is inspired by ptrLx's [OneShot](https://github.com/ptrLx/OneShot).

### Features:
- Take daily logs
- Markdown support
- Keep photo memories
- Reminder notifications
- Record your mood
- Search your past logs
- Material You design
- Set custom storage locations
- Json Import/Export
- Photo gallery
- Log calendar

## Screenshots
<p>
<img width="200" src="https://github.com/Demizo/Daily_You/blob/master/screenshots/Screenshot_0.png" alt="app screenshot">
<img width="200" src="https://github.com/Demizo/Daily_You/blob/master/screenshots/Screenshot_1.png" alt="app screenshot">
<img width="200" src="https://github.com/Demizo/Daily_You/blob/master/screenshots/Screenshot_2.png" alt="app screenshot">
<img width="200" src="https://github.com/Demizo/Daily_You/blob/master/screenshots/Screenshot_3.png" alt="app screenshot">
<img width="200" src="https://github.com/Demizo/Daily_You/blob/master/screenshots/Screenshot_4.png" alt="app screenshot">
<img width="200" src="https://github.com/Demizo/Daily_You/blob/master/screenshots/Screenshot_5.png" alt="app screenshot">
</p>

## Installation
### Android
<a href="https://apt.izzysoft.de/fdroid/index/apk/com.demizo.daily_you/"><img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroid.png" alt="Get it on IzzyOnDroid" height="100"></a>

Or download the latest APK from [releases](https://github.com/Demizo/Daily_You/releases).

### Linux (Beta)
Download the latest Appimage from [releases](https://github.com/Demizo/Daily_You/releases). [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher) recommended.

## Migrate From Another App
Are you coming from another app? Daily You supports migration from other apps! If the app you use isn't listed below feel free to request it. **Note:** Imports from some apps may not be one-to-one since Daily You likely has different features/limitations.
### OneShot
Within OneShot's settings, entries can be exported as a JSON file. The JSON file can be directly imported into Daily You by going to `Settings > Import Logs... > OneShot`. Images can be imported by using the `Import Images` option and selecting all of your OneShot photos. Alternatively, you can set your `Image Folder` to be the same folder where OneShot saved its images.
### Daylio
Daylio has a very different set of features from Daily You and as such lacks a one-to-one import. Steps, as well as a helper script, for migrating from Daylio are provided in this repo [daylio-to-daily-you](https://github.com/Demizo/daylio-to-daily-you).
## Development
Daily You is built using Flutter.
- Clone the repo
- Install Flutter dependencies
- Setup with `flutter pub get`

## License
This software is free software licensed under the GNU General Public License 3.0.
