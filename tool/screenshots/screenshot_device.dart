// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:golden_screenshot/golden_screenshot.dart';

final fastlanePhoneDevice = ScreenshotDevice(
  platform: GoldenScreenshotDevices.androidPhone.device.platform,
  resolution: GoldenScreenshotDevices.androidPhone.device.resolution,
  pixelRatio: GoldenScreenshotDevices.androidPhone.device.resolution.width /
      (1080 / 2.625),
  goldenSubFolder: GoldenScreenshotDevices.androidPhone.device.goldenSubFolder,
  frameBuilder: ScreenshotFrame.noFrame,
);
