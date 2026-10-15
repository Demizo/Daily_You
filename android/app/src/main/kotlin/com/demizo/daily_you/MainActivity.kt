// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.Intent;

class MainActivity: FlutterFragmentActivity() {
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
  }
}
