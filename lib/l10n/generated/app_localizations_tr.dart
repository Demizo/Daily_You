// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Bugünü Kayıtla!';

  @override
  String get dailyReminderDescription => 'Günlük kaydı oluştur…';

  @override
  String get pageHomeTitle => 'Ana';

  @override
  String get flashbacksTitle => 'Geçmiş';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Kötü günleri çıkar';

  @override
  String get flaskbacksEmpty => 'Henüz geçmiş yok…';

  @override
  String get flashbackGoodDay => 'İyi Bir Gün';

  @override
  String get flashbackRandomDay => 'Rastgele Bir Gün';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hafta önce',
      one: '$count hafta önce',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ay önce',
      one: '$count ay önce',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıl önce',
      one: '$count yıl önce',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => 'Galeri';

  @override
  String get searchLogsHint => 'Kayıt ara…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt',
      one: '$count kayıt',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sözcük',
      one: '$count sözcük',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Kayıt yok…';

  @override
  String get sortDateTitle => 'Tarih';

  @override
  String get sortOrderAscendingTitle => 'Artan';

  @override
  String get sortOrderDescendingTitle => 'Azalan';

  @override
  String get pageStatisticsTitle => 'Sayımlama';

  @override
  String get statisticsNotEnoughData => 'Yeterli veri yok…';

  @override
  String get statisticsRangeOneMonth => '1 ay';

  @override
  String get statisticsRangeSixMonths => '6 ay';

  @override
  String get statisticsRangeOneYear => '1 yıl';

  @override
  String get statisticsRangeAllTime => 'Tüm zamanlar';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Özeti';
  }

  @override
  String chartByDayTitle(Object tag) {
    return 'Günlük $tag';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mevcut seri $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En uzun seri $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Geçen son kötü gün $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Harici depolamaya erişilemiyor';

  @override
  String get errorExternalStorageAccessDescription =>
      'Ağ depolama alanını kullanıyorsanız, hizmetin çevrim içi olduğundan ve ağ erişiminiz olduğundan emin olun.\n\nAksi takdirde, uygulama harici klasör için izinleri kaybetmiş olabilir. Ayarlara gidin ve erişim vermek için harici klasörü yeniden seçin.\n\nUyarı, harici depolama konumuna erişimi geri yükleyene kadar değişiklikler eşlenemeyecektir!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Yerel veri tabanı ile devam edin';

  @override
  String get lastModified => 'Değişiklik';

  @override
  String get writeSomethingHint => 'Bir şeyler yaz…';

  @override
  String get titleHint => 'Başlık…';

  @override
  String get deleteLogTitle => 'Kaydı sil';

  @override
  String get deleteLogDescription => 'Bu kaydı silmek istiyor musun?';

  @override
  String get deletePhotoTitle => 'Fotoğrafı sil';

  @override
  String get deletePhotoDescription => 'Bu fotoğrafı silmek istiyor musun?';

  @override
  String get pageSettingsTitle => 'Ayarlar';

  @override
  String get settingsAppearanceTitle => 'Görünüm';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Aydınlık';

  @override
  String get themeDark => 'Karanlık';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Haftanın ilk günü';

  @override
  String get settingsUseSystemAccentColor => 'Sistem vurgu rengini kullan';

  @override
  String get settingsCustomAccentColor => 'Özel vurgu rengi';

  @override
  String get settingsShowMarkdownToolbar => 'Markdown araç çubuğunu göster';

  @override
  String get settingsShowFlashbacks => 'Bilgi Kartlarını Göster';

  @override
  String get settingsChangeMoodIcons => 'Ruh hali simgelerini değiştir';

  @override
  String get moodIconPrompt => 'Bir simge belirleyin';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'Bildirimler';

  @override
  String get settingsDailyReminderOnboarding =>
      'Süreklilik için günlük hatırlatıcıları etkinleştirin!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      '\'Takvim alarmları\' izninden bildirimi rastgele bir anda veya tercih ettiğiniz zamanda göndermesi isteyecektir.';

  @override
  String get settingsDailyReminderTitle => 'Günlük Hatırlatma';

  @override
  String get settingsDailyReminderDescription => 'Her gün nazik bir hatırlatma';

  @override
  String get settingsReminderTime => 'Hatırlatma zamanı';

  @override
  String get settingsFixedReminderTimeTitle => 'Sabit hatırlatma zamanı';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Hatırlatma için sabit bir zaman seçin';

  @override
  String get settingsAlwaysSendReminderTitle => 'Daima hatırlatma gönder';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Bir kayıt açılmış olsa bile hatırlatma gönder';

  @override
  String get settingsCustomizeNotificationTitle => 'Bildirimleri özelleştirin';

  @override
  String get settingsTemplatesTitle => 'Şablonlar';

  @override
  String get settingsDefaultTemplate => 'Varsayılan şablon';

  @override
  String get manageTemplates => 'Şablonları yönet';

  @override
  String get addTemplate => 'Bir şablon ekle';

  @override
  String get newTemplate => 'Yeni şablon';

  @override
  String get noTemplateTitle => 'Hiçbiri';

  @override
  String get noTemplatesDescription => 'Henüz şablon oluşturulmadı…';

  @override
  String get settingsStorageTitle => 'Depolama';

  @override
  String get settingsImageQuality => 'Görüntü kalitesi';

  @override
  String get imageQualityHigh => 'Yüksek';

  @override
  String get imageQualityMedium => 'Orta';

  @override
  String get imageQualityLow => 'Düşük';

  @override
  String get imageQualityNoCompression => 'Sıkıştırmadan';

  @override
  String get settingsLogFolder => 'Kayıt klasörü';

  @override
  String get settingsImageFolder => 'Görüntü klasörü';

  @override
  String get warningTitle => 'Uyarı';

  @override
  String get logFolderWarningDescription =>
      'Seçilen klasör zaten bir \'Daily_you.db\' dosyası içeriyorsa, mevcut günlüklerinizin üzerine yazmak için kullanılacaktır!';

  @override
  String get errorTitle => 'Hata';

  @override
  String get logFolderErrorDescription => 'Günlük klasörü değiştirilemedi!';

  @override
  String get imageFolderErrorDescription => 'Görüntü klasörü değiştirilemedi!';

  @override
  String get backupErrorDescription => 'Yedekleme oluşturulamadı!';

  @override
  String get restoreErrorDescription => 'Yedekleme geri yüklenemedi!';

  @override
  String get settingsBackupRestoreTitle => 'Yedekleme ve Geri yükleme';

  @override
  String get settingsBackup => 'Yedekle';

  @override
  String get settingsRestore => 'Geri yükleme';

  @override
  String get settingsRestorePromptDescription =>
      'Bir yedeklemeyi geri yüklemek mevcut verilerinizin üzerine yazacaktır!';

  @override
  String tranferStatus(Object percent) {
    return 'Aktarılıyor… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Yedekleme oluşturuluyor… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Yedekleme geri yükleniyor… $percent%';
  }

  @override
  String get cleanUpStatus => 'Temizleniyor…';

  @override
  String get settingsExport => 'Dışa aktar';

  @override
  String get settingsExportToAnotherFormat => 'Başka Bir Formatta Dışarı Aktar';

  @override
  String get settingsExportFormatDescription =>
      'Bu yedek olarak kullanılmamalıdır!';

  @override
  String get exportLogs => 'Kayıtları dışa aktar';

  @override
  String get exportImages => 'Görselleri dışa aktar';

  @override
  String get settingsImport => 'İçe aktar';

  @override
  String get settingsImportFromAnotherApp => 'Başka bir uygulamadan içe aktar';

  @override
  String get settingsTranslateCallToAction => 'Herkes bir günlüğe erişebilir!';

  @override
  String get settingsHelpTranslate => 'Çeviri yardımı';

  @override
  String get importLogs => 'Kayıtları içe aktar';

  @override
  String get importImages => 'Görselleri içe aktar';

  @override
  String get logFormatTitle => 'Biçim seçin';

  @override
  String get logFormatDescription =>
      'Başka bir uygulamanın formatı tüm özellikleri desteklemeyebilir. Üçüncü taraf formatlar her an değişebileceğinden dolayı lütfen herhangi bir sorunu bildirin. Bu mevcut günlükleri etkilemez!';

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
  String get formatOneShot => 'Tek çekim';

  @override
  String get formatPixels => 'Pixels';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => 'Tüm kayıtları sil';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Tüm kayıtlarınızı silmek istiyor musunuz?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Onaylamak için \'$prompt\' girin. Bu geri alınamaz!';
  }

  @override
  String get settingsLanguageTitle => 'Dil';

  @override
  String get settingsAppLanguageTitle => 'Uygulama Dili';

  @override
  String get settingsOverrideAppLanguageTitle => 'Uygulama Dilini Özelleştir';

  @override
  String get settingsSecurityTitle => 'Güvenlik';

  @override
  String get settingsSecurityRequirePassword => 'Şifre Gerektir';

  @override
  String get settingsSecurityEnterPassword => 'Şifre Gir';

  @override
  String get settingsSecuritySetPassword => 'Şifre Belirle';

  @override
  String get settingsSecurityChangePassword => 'Şifre Değiştir';

  @override
  String get settingsSecurityPassword => 'Şifre';

  @override
  String get settingsSecurityConfirmPassword => 'Şifreyi Doğrula';

  @override
  String get settingsSecurityOldPassword => 'Eski Şifre';

  @override
  String get settingsSecurityIncorrectPassword => 'Yanlış Şifre';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get requiredPrompt => 'Gerekli';

  @override
  String get settingsSecurityBiometricUnlock => 'Biyometrik Açma';

  @override
  String get unlockAppPrompt => 'Uygulamayı Aç';

  @override
  String get settingsAboutTitle => 'Hakkında';

  @override
  String get settingsVersion => 'Sürüm';

  @override
  String get settingsLicense => 'Lisans';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Kaynak kodu';

  @override
  String get settingsMadeWithLove => '❤️ ile yapılmıştır';

  @override
  String get settingsConsiderSupporting => 'desteklemeyi düşünün';

  @override
  String get tagMoodTitle => 'Ruh hali';
}
