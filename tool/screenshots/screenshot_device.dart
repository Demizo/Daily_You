import 'package:golden_screenshot/golden_screenshot.dart';

final fastlanePhoneDevice = ScreenshotDevice(
  platform: GoldenScreenshotDevices.androidPhone.device.platform,
  resolution: GoldenScreenshotDevices.androidPhone.device.resolution,
  pixelRatio: GoldenScreenshotDevices.androidPhone.device.pixelRatio,
  goldenSubFolder: GoldenScreenshotDevices.androidPhone.device.goldenSubFolder,
  frameBuilder: ScreenshotFrame.noFrame,
);
