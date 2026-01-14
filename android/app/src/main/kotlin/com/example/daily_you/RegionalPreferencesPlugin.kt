package com.example.regional_preferences

import android.os.Build
import androidx.annotation.NonNull
import androidx.core.text.util.LocalePreferences
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class RegionalPreferencesPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "regional_preferences")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getFirstDayOfWeekIndex" -> {
                result.success(getFirstDayOfWeekIndex())
            }
            else -> result.notImplemented()
        }
    }

    private fun getFirstDayOfWeekIndex(): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return null
        }

        val firstDay = LocalePreferences.getFirstDayOfWeek()

        return when (firstDay) {
            LocalePreferences.FirstDayOfWeek.MONDAY -> 0
            LocalePreferences.FirstDayOfWeek.TUESDAY -> 1
            LocalePreferences.FirstDayOfWeek.WEDNESDAY -> 2
            LocalePreferences.FirstDayOfWeek.THURSDAY -> 3
            LocalePreferences.FirstDayOfWeek.FRIDAY -> 4
            LocalePreferences.FirstDayOfWeek.SATURDAY -> 5
            LocalePreferences.FirstDayOfWeek.SUNDAY -> 6
            else -> null
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

