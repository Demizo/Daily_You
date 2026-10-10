// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/storage/platform_secret_store.dart';

abstract interface class SecretStore {
  static SecretStore instance = const PlatformSecretStore();

  Future<bool> isAvailable();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}
