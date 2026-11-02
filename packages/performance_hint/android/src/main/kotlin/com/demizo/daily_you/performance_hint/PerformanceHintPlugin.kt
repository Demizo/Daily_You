// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you.performance_hint

import android.content.Context
import android.os.Build
import android.os.PerformanceHintManager
import android.os.Process
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class PerformanceHintPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var session: PerformanceHintManager.Session? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "performance_hint")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        session?.close()
        session = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "boost" -> {
                boost()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun boost() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val activeSession = session ?: createSession() ?: return
        activeSession.reportActualWorkDuration(BOOST_NANOS)
    }

    private fun createSession(): PerformanceHintManager.Session? {
        val manager = context.getSystemService(Context.PERFORMANCE_HINT_SERVICE) as? PerformanceHintManager
            ?: return null
        val threadIds = (engineThreadIds() + Process.myPid()).toIntArray()
        session = manager.createHintSession(threadIds, TARGET_NANOS)
        return session
    }

    private fun engineThreadIds(): List<Int> =
        File("/proc/self/task").listFiles().orEmpty().mapNotNull { task ->
            val name = File(task, "comm").readText().trim()
            if (name in ENGINE_THREAD_NAMES) task.name.toInt() else null
        }

    private companion object {
        const val TARGET_NANOS = 11_000_000L
        const val BOOST_NANOS = TARGET_NANOS * 3
        val ENGINE_THREAD_NAMES = setOf("1.ui", "1.raster")
    }
}
