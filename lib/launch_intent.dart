// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

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
