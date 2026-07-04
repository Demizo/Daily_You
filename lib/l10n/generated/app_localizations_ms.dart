// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Log hari ini!';

  @override
  String get dailyReminderDescription => 'Ambil log harian anda…';

  @override
  String get actionTakePhoto => 'Ambil gambar';

  @override
  String get actionToday => 'Hari ini';

  @override
  String get actionOtherDay => 'Hari lain';

  @override
  String get pageHomeTitle => 'Utama';

  @override
  String get flashbacksTitle => 'Imbas kembali';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Kecualikan hari-hari buruk';

  @override
  String get flaskbacksEmpty => 'Belum ada imbas semula…';

  @override
  String get flashbackGoodDay => 'Hari yang baik';

  @override
  String get flashbackRandomDay => 'Hari yang rawak';

  @override
  String flashbackWeek(num count) {
    return '$count Minggu Lepas';
  }

  @override
  String flashbackMonth(num count) {
    return '$count Bulan Lepas';
  }

  @override
  String flashbackYear(num count) {
    return '$count Tahun Lepas';
  }

  @override
  String get flashbackOnThisDay => 'Pada Hari Ini';

  @override
  String get pageGalleryTitle => 'Galeri';

  @override
  String get searchLogsHint => 'Log carian…';

  @override
  String logCount(num count) {
    return '$count log';
  }

  @override
  String dayCount(num count) {
    return '$count hari';
  }

  @override
  String wordCount(num count) {
    return '$count perkataan';
  }

  @override
  String get noLogs => 'Tiada log…';

  @override
  String get sortDateTitle => 'Tarikh';

  @override
  String get sortOrderAscendingTitle => 'Menaik';

  @override
  String get sortOrderDescendingTitle => 'Menurun';

  @override
  String get pageStatisticsTitle => 'Statistik';

  @override
  String get statisticsNotEnoughData => 'Tidak cukup data…';

  @override
  String get statisticsRangeOneMonth => '1 Bulan';

  @override
  String get statisticsRangeSixMonths => '6 Bulan';

  @override
  String get statisticsRangeOneYear => '1 Tahun';

  @override
  String get statisticsRangeAllTime => 'Setiap Masa';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Ringkasan';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Per Hari';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag Dari Semasa Ke Semasa';
  }

  @override
  String get chartGroupingLabel => 'Group by';

  @override
  String get chartGroupingDay => 'Day';

  @override
  String get chartGroupingWeek => 'Week';

  @override
  String get chartGroupingMonth => 'Month';

  @override
  String get chartGroupingYear => 'Year';

  @override
  String get chartSmoothingLabel => 'Smoothing';

  @override
  String streakCurrent(num count) {
    return 'Rentetan Semasa $count';
  }

  @override
  String streakLongest(num count) {
    return 'Rentetan Terpanjang $count';
  }

  @override
  String streakSinceBadDay(num count) {
    return 'Hari Semenjak Hari Yang Buruk $count';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Tidak Dapat Mengakses Storan Luaran';

  @override
  String get errorExternalStorageAccessDescription =>
      'Jika anda menggunakan storan rangkaian, pastikan perkhidmatan tersebut dalam talian dan anda mempunyai akses rangkaian.\n\nJika tidak, aplikasi mungkin akan kehilangan kebenaran untuk folder luaran. Pergi ke tetapan dan pilih semula folder luaran untuk memberikan akses.\n\nAmaran, perubahan tidak akan disegerakkan sehingga anda memulihkan akses ke lokasi storan luaran!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Teruskan Dengan Pangkalan Data Tempatan';

  @override
  String get lastModified => 'Diubah suai';

  @override
  String get writeSomethingHint => 'Tulis sesuatu…';

  @override
  String get titleHint => 'Tajuk…';

  @override
  String get deleteLogTitle => 'Padam Log';

  @override
  String get deleteLogDescription => 'Adakah anda ingin memadam log ini?';

  @override
  String get deletePhotoTitle => 'Padam Foto';

  @override
  String get deletePhotoDescription => 'Adakah anda ingin memadam foto ini?';

  @override
  String get pageSettingsTitle => 'Tetapan';

  @override
  String get settingsAppearanceTitle => 'Penampilan';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Hari Pertama Dalam Seminggu';

  @override
  String get settingsCalendarSystem => 'Sistem Kalendar';

  @override
  String get calendarSystemGregorian => 'Gregorian';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor => 'Gunakan Warna Tema Sistem';

  @override
  String get settingsCustomAccentColor => 'Warna Tema Tersuai';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Tunjukkan Imbasan Semula';

  @override
  String get settingsChangeMoodIcons => 'Tukar Ikon Emosi';

  @override
  String get moodIconPrompt => 'Masukkan Ikon';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Susun Atur Paparan Galeri';

  @override
  String get settingsHideImagesInGallery => 'Sembunyikan Imej Dalam Galeri';

  @override
  String get settingsHideImages => 'Sembunyikan Imej';

  @override
  String get pageCalendarTitle => 'Kalendar';

  @override
  String get viewLayoutList => 'Senarai';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'Pemberitahuan';

  @override
  String get settingsDailyReminderOnboarding =>
      'Dayakan peringatan harian untuk memastikan diri anda konsisten!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Kebenaran \'jadualkan penggera\' akan diminta untuk menghantar peringatan pada waktu tertentu atau pada waktu pilihan anda.';

  @override
  String get settingsDailyReminderTitle => 'Peringatan Harian';

  @override
  String get settingsOnThisDayDescription => 'Imbas kembali memori lama';

  @override
  String get settingsDailyReminderDescription =>
      'Peringatan lembut setiap hari';

  @override
  String get settingsReminderTime => 'Masa Peringatan';

  @override
  String get settingsFixedReminderTimeTitle => 'Masa Peringatan Tetap';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Pilih masa yang tetap untuk peringatan';

  @override
  String get settingsAlwaysSendReminderTitle => 'Semtiasa Hantar Peringatan';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Hantar peringatan walaupun log telah dimulakan';

  @override
  String get settingsCustomizeNotificationTitle => 'Sesuaikan Pemberitahuan';

  @override
  String get settingsTemplatesTitle => 'Templat';

  @override
  String get settingsDefaultTemplate => 'Templat Asal';

  @override
  String get manageTemplates => 'Urus Templat';

  @override
  String get addTemplate => 'Tambah Templat';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'Tiada';

  @override
  String get noTemplatesDescription => 'Tiada templat dicipta…';

  @override
  String get templateVariableTime => 'Masa';

  @override
  String get templateDefaultTimestampTitle => 'Tanda Masa';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Ringkasan Hari';

  @override
  String get templateDefaultSummaryBody =>
      '### Ringkasan\n- \n\n### Petikan\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Refleksi';

  @override
  String get templateDefaultReflectionBody =>
      '### Apakah yang anda nikmati hari ini?\n- \n\n### Apakah yang anda syukuri?\n- \n\n### Apakah yang anda nanti-nantikan?\n- ';

  @override
  String get settingsStorageTitle => 'Storan';

  @override
  String get settingsImageQuality => 'Kualiti Imej';

  @override
  String get imageQualityHigh => 'Tinggi';

  @override
  String get imageQualityMedium => 'Sederhana';

  @override
  String get imageQualityLow => 'Rendah';

  @override
  String get imageQualityNoCompression => 'Tiada Pemampatan';

  @override
  String get settingsLogFolder => 'Folder Log';

  @override
  String get settingsImageFolder => 'Folder Imej';

  @override
  String get warningTitle => 'Amaran';

  @override
  String get logFolderWarningDescription =>
      'Jika folder yang dipilih telah mengandungi fail \'daily_you.db\', ia akan digunakan untuk menulis semula log sedia ada anda!';

  @override
  String get errorTitle => 'Ralat';

  @override
  String get logFolderErrorDescription => 'Gagal menukar folder log!';

  @override
  String get imageFolderErrorDescription => 'Gagal menukar folder imej!';

  @override
  String get backupErrorDescription => 'Gagal mencipta sandaran!';

  @override
  String get restoreErrorDescription => 'Gagal memulihkan sandaran!';

  @override
  String get settingsBackupRestoreTitle => 'Sandaran & Pemulihan';

  @override
  String get settingsBackup => 'Sandarkan';

  @override
  String get settingsRestore => 'Pulihkan';

  @override
  String get settingsRestorePromptDescription =>
      'Memulihkan sandaran akan menulis semula data sedia ada anda!';

  @override
  String tranferStatus(Object percent) {
    return 'Memindahkan... $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Mencipta Sandaran... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Memulihkan Sandaran... $percent%';
  }

  @override
  String get cleanUpStatus => 'Membersihkan…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Eksport Kepada Format Lain';

  @override
  String get settingsExportFormatDescription =>
      'Ini tidak boleh digunakan sebagai sandaran!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Import Daripada Aplikasi Lain';

  @override
  String get settingsTranslateCallToAction =>
      'Setiap orang harus mempunyai akses kepada jurnal!';

  @override
  String get settingsHelpTranslate => 'Bantu Terjemahkan';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Pilih Format';

  @override
  String get logFormatDescription =>
      'Format aplikasi lain mungkin tidak menyokong semua ciri. Sila laporkan sebarang isu kerana format pihak ketiga mungkin berubah pada bila-bila masa. Ini tidak akan menjejaskan log sedia ada!';

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
  String get settingsDeleteAllLogsTitle => 'Padam Semua Log';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Adakah anda ingin memadam semua log anda?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Masukkan \'$prompt\' untuk meneruskan. Ini tidak dapat dibatalkan!';
  }

  @override
  String get settingsLanguageTitle => 'Bahasa';

  @override
  String get settingsAppLanguageTitle => 'Bahasa Apl';

  @override
  String get settingsOverrideAppLanguageTitle => 'Bahasa Aplikasi Ganti';

  @override
  String get settingsSecurityTitle => 'Keselamatan';

  @override
  String get settingsSecurityRequirePassword => 'Memerlukan Kata Laluan';

  @override
  String get settingsSecurityEnterPassword => 'Masukkan Kata Laluan';

  @override
  String get settingsSecuritySetPassword => 'Tetapkan Kata Laluan';

  @override
  String get settingsSecurityChangePassword => 'Tukar Kata Laluan';

  @override
  String get settingsSecurityPassword => 'Kata Laluan';

  @override
  String get settingsSecurityConfirmPassword => 'Sahkan Kata Laluan';

  @override
  String get settingsSecurityOldPassword => 'Kata Laluan Lama';

  @override
  String get settingsSecurityIncorrectPassword => 'Kata Laluan Salah';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Kata laluan tidak sepadan';

  @override
  String get requiredPrompt => 'Diperlukan';

  @override
  String get settingsSecurityBiometricUnlock => 'Buka Kunci Biometrik';

  @override
  String get unlockAppPrompt => 'Buka kunci apl';

  @override
  String get settingsAboutTitle => 'Tentang';

  @override
  String get settingsVersion => 'Versi';

  @override
  String get settingsLicense => 'Lesen';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Kod Sumber';

  @override
  String get settingsMadeWithLove => 'Dibuat dengan ❤️';

  @override
  String get settingsConsiderSupporting => 'pertimbangkan untuk menyokong';

  @override
  String get imagesTitle => 'Images';

  @override
  String get tagMoodTitle => 'Suasana';
}
