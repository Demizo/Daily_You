package com.demizo.daily_you.share_receiver

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.core.content.IntentCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.UUID

class ShareReceiverPlugin : FlutterPlugin, ActivityAware, NewIntentListener, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingShare: Intent? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "share_receiver")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        val launchIntent = binding.activity.intent
        // Android replays the original intent when a task is reopened from recents.
        val launchedFromHistory =
            launchIntent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        if (isShare(launchIntent) && !launchedFromHistory) pendingShare = launchIntent
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        if (!isShare(intent)) return false
        pendingShare = intent
        channel.invokeMethod("shareReceived", null)
        return true
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "consumeShare" -> consumeShare(result)
            else -> result.notImplemented()
        }
    }

    private fun isShare(intent: Intent): Boolean {
        return intent.action == Intent.ACTION_SEND || intent.action == Intent.ACTION_SEND_MULTIPLE
    }

    private fun consumeShare(result: Result) {
        val share = pendingShare
        pendingShare = null
        // A recreated activity would otherwise deliver this share again.
        activityBinding?.activity?.intent = Intent()
        if (share == null) {
            result.success(null)
            return
        }
        val text = share.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        val uris = streamUris(share)
        CoroutineScope(Dispatchers.IO).launch {
            val imagePaths = copyImagesToCache(uris)
            withContext(Dispatchers.Main) {
                result.success(mapOf("text" to text, "imagePaths" to imagePaths))
            }
        }
    }

    private fun streamUris(share: Intent): List<Uri> {
        if (share.action == Intent.ACTION_SEND_MULTIPLE) {
            return IntentCompat.getParcelableArrayListExtra(share, Intent.EXTRA_STREAM, Uri::class.java)
                ?: emptyList()
        }
        return listOfNotNull(IntentCompat.getParcelableExtra(share, Intent.EXTRA_STREAM, Uri::class.java))
    }

    // Each share gets its own directory so a second share cannot delete images the first still shows.
    private fun copyImagesToCache(uris: List<Uri>): List<String> {
        val root = File(context.cacheDir, "shared_images")
        deleteStaleShares(root)
        val directory by lazy { File(root, UUID.randomUUID().toString()).also { it.mkdirs() } }
        val paths = mutableListOf<String>()
        for ((index, uri) in uris.withIndex()) {
            try {
                val mimeType = context.contentResolver.getType(uri) ?: continue
                if (!mimeType.startsWith("image/")) continue
                val target = File(directory, "${index}_${displayName(uri, mimeType)}")
                context.contentResolver.openInputStream(uri)?.use { input ->
                    target.outputStream().use { output -> input.copyTo(output) }
                } ?: continue
                paths.add(target.path)
            } catch (error: Exception) {
                Log.w(TAG, "Skipping shared image that could not be copied: $uri", error)
            }
        }
        return paths
    }

    private fun deleteStaleShares(root: File) {
        val cutoff = System.currentTimeMillis() - STALE_SHARE_MILLISECONDS
        root.listFiles()?.filter { it.lastModified() < cutoff }?.forEach { it.deleteRecursively() }
    }

    private fun displayName(uri: Uri, mimeType: String): String {
        val name = context.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
            ?.replace('/', '_')
            ?: "shared_image"
        if (name.substringAfterLast('.', "").isNotEmpty()) return name
        val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType) ?: "jpg"
        return "$name.$extension"
    }

    private companion object {
        const val TAG = "ShareReceiver"
        const val STALE_SHARE_MILLISECONDS = 24 * 60 * 60 * 1000L
    }
}
