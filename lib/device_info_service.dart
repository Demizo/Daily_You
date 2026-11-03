// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:daily_you/launch_intent.dart';
import 'package:daily_you/storage/secret_store.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  int? androidSdk;
  String? model;
  PackageInfo? appInfo;
  bool? supportsBiometrics;
  bool? supportsSecureStorage;
  LaunchIntent? launchIntent;

  Future<void> init() async {
    // Các thông tin hệ điều hành chỉ lấy trên nền tảng native.
    if (!kIsWeb) {
      final plugin = DeviceInfoPlugin();

      appInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        final androidInfo = await plugin.androidInfo;

        androidSdk = androidInfo.version.sdkInt;
        model = androidInfo.model;

        final auth = LocalAuthentication();
        supportsBiometrics = await auth.canCheckBiometrics;
      }
    } else {
      // Các thông tin Android không áp dụng trên trình duyệt.
      supportsBiometrics = false;
    }

    supportsSecureStorage = await SecretStore.instance.isAvailable();
  }
}
