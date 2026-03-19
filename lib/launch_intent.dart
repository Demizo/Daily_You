sealed class LaunchIntent {
  const LaunchIntent();

  const factory LaunchIntent.logToday() = LogTodayIntent;
  const factory LaunchIntent.takePhoto() = TakePhotoIntent;
}

class TakePhotoIntent extends LaunchIntent {
  const TakePhotoIntent();
}

class LogTodayIntent extends LaunchIntent {
  const LogTodayIntent();
}
