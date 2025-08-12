import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File


/** MediaScannerPlugin */
class MediaScannerPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "media_scanner")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "refreshGallery") {
            val path: String? = call.argument("path")
            result.success(refreshMedia(path))
        } else {
            result.notImplemented()
        }
    }

    /// function to refresh media on Android Device
    private fun refreshMedia(path: String?): String {
        return try {
            if (path == null)
                throw NullPointerException()
            val file = File(path)
            if (android.os.Build.VERSION.SDK_INT < 29) {
                context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.fromFile(file)))
            } else {
                MediaScannerConnection.scanFile(context, arrayOf(file.toString()),
                        arrayOf(file.name), null)
            }
            Log.d("Media Scanner", "Success show image $path in Gallery")
            "Success show image $path in Gallery"
        } catch (e: Exception) {
            Log.e("Media Scanner", e.toString())
            e.toString()
        }

    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
