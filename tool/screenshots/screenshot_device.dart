import 'package:golden_screenshot/golden_screenshot.dart';

final fastlanePhoneDevice = ScreenshotDevice(
  platform: GoldenScreenshotDevices.androidPhone.device.platform,
  resolution: GoldenScreenshotDevices.androidPhone.device.resolution,
  pixelRatio: GoldenScreenshotDevices.androidPhone.device.resolution.width /
      (1080 / 2.625),
  goldenSubFolder: GoldenScreenshotDevices.androidPhone.device.goldenSubFolder,
  frameBuilder: ScreenshotFrame.noFrame,
);
