sealed class LaunchIntent {
  const LaunchIntent();

  const factory LaunchIntent.logToday() = LogTodayIntent;
  const factory LaunchIntent.takePhoto() = TakePhotoIntent;
  const factory LaunchIntent.shareFiles(List<String> filePaths) =
      ShareFilesIntent;
}

class TakePhotoIntent extends LaunchIntent {
  const TakePhotoIntent();
}

class LogTodayIntent extends LaunchIntent {
  const LogTodayIntent();
}

/// Carries local file paths (as resolved by the `receive_sharing_intent`
/// plugin from content:// URIs) for images the user shared to Daily You.
class ShareFilesIntent extends LaunchIntent {
  final List<String> filePaths;
  const ShareFilesIntent(this.filePaths);
}
