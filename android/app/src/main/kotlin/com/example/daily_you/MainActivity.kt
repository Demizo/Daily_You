package com.demizo.daily_you

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import SafTransferPlugin
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.demizo.daily_you/share"
    private var pendingUris: List<String>? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(SafTransferPlugin())
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedFiles" -> {
                    result.success(pendingUris)
                    pendingUris = null
                }
                "readFileBytes" -> {
                    val uriString = call.argument<String>("uri")
                    Thread {
                        try {
                            val uri = Uri.parse(uriString)
                            val bytes = contentResolver.openInputStream(uri)?.readBytes()
                            result.success(bytes)
                        } catch (e: Exception) {
                            result.error("READ_ERROR", e.message, null)
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
        // Deliver to Flutter immediately if engine is already running
        val uris = pendingUris
        if (uris != null) {
            pendingUris = null
            methodChannel?.invokeMethod("onSharedFiles", uris)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun handleIntent(intent: Intent) {
        try {
            when (intent.action) {
                Intent.ACTION_SEND -> {
                    if (intent.type?.startsWith("image/") == true) {
                        @Suppress("DEPRECATION")
                        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                        if (uri != null) {
                            // Workaround: some ROMs don't propagate URI read permission reliably
                            grantUriPermission(packageName, uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            pendingUris = listOf(uri.toString())
                        }
                    }
                }
                Intent.ACTION_SEND_MULTIPLE -> {
                    if (intent.type?.startsWith("image/") == true) {
                        @Suppress("DEPRECATION")
                        val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                        if (!uris.isNullOrEmpty()) {
                            uris.forEach { uri ->
                                try {
                                    grantUriPermission(packageName, uri,
                                        Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                } catch (_: Exception) {}
                            }
                            pendingUris = uris.map { it.toString() }
                        }
                    }
                }
            }
        } catch (_: Exception) {}
    }
}
