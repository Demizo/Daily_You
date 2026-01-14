package com.demizo.daily_you

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.regional_preferences.RegionalPreferencesPlugin
import android.content.Intent;

class MainActivity: FlutterFragmentActivity() {
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(RegionalPreferencesPlugin())
    }
}
