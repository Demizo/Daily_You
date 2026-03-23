// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => '오늘을 기록하세요!';

  @override
  String get dailyReminderDescription => '하루를 기록해보세요…';

  @override
  String get actionTakePhoto => 'Take photo';

  @override
  String get pageHomeTitle => '홈';

  @override
  String get flashbacksTitle => '회상';

  @override
  String get settingsFlashbacksExcludeBadDays => '나쁜 날들 제외';

  @override
  String get flaskbacksEmpty => '아직 회상할 것이 없습니다…';

  @override
  String get flashbackGoodDay => '좋은 날';

  @override
  String get flashbackRandomDay => '임의의 날';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 주 전',
      one: '$count 주 전',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 달 전',
      one: '$count 달 전',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 년 전',
      one: '$count 년 전',
    );
    return '$_temp0';
  }

  @override
  String get pageGalleryTitle => '갤러리';

  @override
  String get searchLogsHint => '기록 검색…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 개의 기록',
      one: '$count 개의 기록',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 단어',
      one: '$count 단어',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => '기록 없음…';

  @override
  String get sortDateTitle => '날짜';

  @override
  String get sortOrderAscendingTitle => '오름차순';

  @override
  String get sortOrderDescendingTitle => '내림차순';

  @override
  String get pageStatisticsTitle => '통계';

  @override
  String get statisticsNotEnoughData => '데이터가 충분하지 않습니다…';

  @override
  String get statisticsRangeOneMonth => '한 달';

  @override
  String get statisticsRangeSixMonths => '6개월';

  @override
  String get statisticsRangeOneYear => '일 년';

  @override
  String get statisticsRangeAllTime => '전체 기간';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag 요약';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag 날짜로';
  }

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '현재 $count연속',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최장 연속 $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '나쁜 날로부터 $count일',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle => '외부 저장소 접근 불가';

  @override
  String get errorExternalStorageAccessDescription =>
      '네트워크 저장소를 사용하는 경우 서비스가 온라인이고 네트워크 접근 권한을 가지고 있는지 확인하십시오.\n\n그렇지 않다면, 앱이 외부 폴더 접근 권한을 잃어버렸을 수 있습니다. 설정에서 외부폴더 접근 권한을 다시 부여하십시오.\n\n경고, 외부 저장소의 접근 권한을 복구하기 전까지 변경사항이 동기화 되지 않습니다!';

  @override
  String get errorExternalStorageAccessContinue => '로컬 데이터베이스로 계속';

  @override
  String get lastModified => '변경됨';

  @override
  String get writeSomethingHint => '뭔가 적어보세요…';

  @override
  String get titleHint => '제목…';

  @override
  String get deleteLogTitle => '기록 삭제';

  @override
  String get deleteLogDescription => '이 기록을 삭제하시겠습니까?';

  @override
  String get deletePhotoTitle => '사진 삭제';

  @override
  String get deletePhotoDescription => '이 사진을 삭제하시겠습니까?';

  @override
  String get pageSettingsTitle => '설정';

  @override
  String get settingsAppearanceTitle => '외형';

  @override
  String get settingsTheme => '테마';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => '한 주의 시작';

  @override
  String get settingsUseSystemAccentColor => '시스템 강조 색상 사용';

  @override
  String get settingsCustomAccentColor => '커스텀 강조 색상';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => '회상 표시';

  @override
  String get settingsChangeMoodIcons => '기분 아이콘 변경';

  @override
  String get moodIconPrompt => '아이콘 입력';

  @override
  String get settingsFlashbacksViewLayout => '회상 뷰 레이아웃';

  @override
  String get settingsGalleryViewLayout => '갤러리 뷰 레이아웃';

  @override
  String get settingsHideImagesInGallery => '갤러리에서 이미지 숨김';

  @override
  String get viewLayoutList => '리스트';

  @override
  String get viewLayoutGrid => '그리드';

  @override
  String get settingsNotificationsTitle => '알림';

  @override
  String get settingsDailyReminderOnboarding => '일일 알림을 활성화 해 꾸준함을 유지하세요!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      '랜덤한 시간이나 선호하는 시간에 리마인더를 보내기 위해 \'스케줄 알림\' 권한이 요청됩니다.';

  @override
  String get settingsDailyReminderTitle => '일일 알림';

  @override
  String get settingsDailyReminderDescription => '매일의 다정한 알림';

  @override
  String get settingsReminderTime => '리마인더 시간';

  @override
  String get settingsFixedReminderTimeTitle => '고정 리마인더 시간';

  @override
  String get settingsFixedReminderTimeDescription => '리마인더를 보낼 고정 시간 선택';

  @override
  String get settingsAlwaysSendReminderTitle => '항상 리마인더 전송';

  @override
  String get settingsAlwaysSendReminderDescription => '기록을 이미 시작했더라도 리마인더를 전송';

  @override
  String get settingsCustomizeNotificationTitle => '알림 커스터마이즈';

  @override
  String get settingsTemplatesTitle => '템플릿';

  @override
  String get settingsDefaultTemplate => '기본 템플릿';

  @override
  String get manageTemplates => '템플릿 관리';

  @override
  String get addTemplate => '템플릿 추가';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => '없음';

  @override
  String get noTemplatesDescription => '아직 템플릿이 생성되지 않았습니다…';

  @override
  String get templateVariableTime => '시간';

  @override
  String get templateDefaultTimestampTitle => '타임스탬프';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => '일일 요약';

  @override
  String get templateDefaultSummaryBody => '### 요약\n- \n\n### 인용\n> ';

  @override
  String get templateDefaultReflectionTitle => '되짚기';

  @override
  String get templateDefaultReflectionBody =>
      '### 오늘 어떤 것이 즐거웠나요?\n- \n\n### 어떤 것에 감사하나요?\n- \n\n### 앞으로 무엇을 기대하나요?\n- ';

  @override
  String get settingsStorageTitle => '저장소';

  @override
  String get settingsImageQuality => '이미지 품질';

  @override
  String get imageQualityHigh => '높음';

  @override
  String get imageQualityMedium => '중간';

  @override
  String get imageQualityLow => '낮음';

  @override
  String get imageQualityNoCompression => '압축 없음';

  @override
  String get settingsLogFolder => '기록 폴더';

  @override
  String get settingsImageFolder => '이미지 폴더';

  @override
  String get warningTitle => '경고';

  @override
  String get logFolderWarningDescription =>
      '이미 \'daily_you.db\' 파일이 존재하는 폴더를 선택할 경우, 존재하는 기록을 덮어쓰게 됩니다!';

  @override
  String get errorTitle => '에러';

  @override
  String get logFolderErrorDescription => '기록 폴더 변경 실패!';

  @override
  String get imageFolderErrorDescription => '이미지 폴더 변경 실패!';

  @override
  String get backupErrorDescription => '백업 생성 실패!';

  @override
  String get restoreErrorDescription => '백업 불러오기 실패!';

  @override
  String get settingsBackupRestoreTitle => '백업 및 복원';

  @override
  String get settingsBackup => '백업';

  @override
  String get settingsRestore => '복원';

  @override
  String get settingsRestorePromptDescription =>
      '백업을 복구하면 이미 존재하는 데이터를 덮어쓰게 됩니다!';

  @override
  String tranferStatus(Object percent) {
    return '전송중… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return '백업 생성 중… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return '백업 복원 중… $percent%';
  }

  @override
  String get cleanUpStatus => '정리 중…';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => '다른 형식으로 내보내기';

  @override
  String get settingsExportFormatDescription => '백업으로 사용을 권장하지 않습니다!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => '다른 앱에서 가져오기';

  @override
  String get settingsTranslateCallToAction => '누구든 일기를 쓸 수 있어야 합니다!';

  @override
  String get settingsHelpTranslate => '번역 지원';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => '형식 선택';

  @override
  String get logFormatDescription =>
      '다른 앱의 형식은 모든 기능을 지원하지 않을 수 있습니다. 서드 파티 형식은 언제든 바뀔 수 있어 문제가 있다면 알려주시기 바랍니다. 이는 존재하는 기록에 영향을 미치지 않습니다!';

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
  String get formatMarkdown => '마크다운';

  @override
  String get settingsDeleteAllLogsTitle => '모든 기록 삭제';

  @override
  String get settingsDeleteAllLogsDescription => '모든 기록을 삭제하시겠습까?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return '확인을 위해 \'$prompt\' 를 입력하세요. 이 변경사항은 되돌릴 수 없습니다!';
  }

  @override
  String get settingsLanguageTitle => '언어';

  @override
  String get settingsAppLanguageTitle => '앱 언어';

  @override
  String get settingsOverrideAppLanguageTitle => '앱 언어 재정의';

  @override
  String get settingsSecurityTitle => '보안';

  @override
  String get settingsSecurityRequirePassword => '비밀번호 사용';

  @override
  String get settingsSecurityEnterPassword => '비밀번호 입력';

  @override
  String get settingsSecuritySetPassword => '비밀번호 설정';

  @override
  String get settingsSecurityChangePassword => '비밀번호 변경';

  @override
  String get settingsSecurityPassword => '비밀번호';

  @override
  String get settingsSecurityConfirmPassword => '비밀번호 확인';

  @override
  String get settingsSecurityOldPassword => '옛 비밀번호';

  @override
  String get settingsSecurityIncorrectPassword => '틀린 비밀번호';

  @override
  String get settingsSecurityPasswordsDoNotMatch => '비밀번호가 일치하지 않음';

  @override
  String get requiredPrompt => '필요';

  @override
  String get settingsSecurityBiometricUnlock => '생체인식 잠금해제';

  @override
  String get unlockAppPrompt => '앱 잠금해제';

  @override
  String get settingsAboutTitle => '정보';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsLicense => '라이센스';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => '소스 코드';

  @override
  String get settingsMadeWithLove => '❤️을 담아 제작';

  @override
  String get settingsConsiderSupporting => '앱을 후원해주세요';

  @override
  String get tagMoodTitle => '기분';
}
