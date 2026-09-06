import android.content.Context
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.io.OutputStream
import androidx.core.net.toUri

class SafTransferPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "saf_transfer")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "copyFromExternal" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val fileUriStr = call.argument<String>("src")!!.toUri()
                        val dest = call.argument<String>("dest")!!
                        val transferId = call.argument<String>("transferId")!!

                        // Get file size for progress calculation
                        val totalSize = DocumentFile.fromSingleUri(context, fileUriStr)?.length() ?: 0L
                        val inputStream = context.contentResolver.openInputStream(fileUriStr)
                        
                        inputStream?.use { input ->
                            val file = File(dest)
                            file.outputStream().use { output ->
                                copyStreamWithProgress(input, output, totalSize, transferId)
                            }
                        }
                        
                        launch(Dispatchers.Main) { result.success(null) }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) { result.error("PluginError", err.message, null) }
                    }
                }
            }

            "copyToExternal" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val treeUriStr = call.argument<String>("treeUri")!!
                        val fileName = call.argument<String>("fileName")!!
                        val mime = call.argument<String>("mime")!!
                        val localSrc = call.argument<String>("localSrc")!!
                        val overwrite = call.argument<Boolean>("overwrite")!!
                        val append = call.argument<Boolean>("append")!!
                        val transferId = call.argument<String>("transferId")!!

                        val totalSize = File(localSrc).length()
                        val dir = DocumentFile.fromTreeUri(context, treeUriStr.toUri())
                            ?: throw Exception("Directory not found")

                        val (newFile, outStream) = createOutStream(dir, fileName, mime, overwrite, append)
                        val inStream = FileInputStream(File(localSrc))

                        val map = HashMap<String, Any?>()
                        map["uri"] = newFile.uri.toString()
                        map["fileName"] = newFile.name

                        inStream.use { input ->
                            outStream.use { output ->
                                copyStreamWithProgress(input, output, totalSize, transferId)
                            }
                        }

                        launch(Dispatchers.Main) { result.success(map) }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) { result.error("PluginError", err.message, null) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private suspend fun copyStreamWithProgress(
        input: InputStream, 
        output: OutputStream, 
        totalSize: Long, 
        transferId: String
    ) {
        val buffer = ByteArray(8 * 1024)
        var bytesRead: Int
        var totalRead: Long = 0
        var lastReportedProgress = 0.0

        while (input.read(buffer).also { bytesRead = it } >= 0) {
            output.write(buffer, 0, bytesRead)
            totalRead += bytesRead

            if (totalSize > 0) {
                val currentProgress = (totalRead.toDouble() / totalSize) * 100
                
                // Report progress every ~5% or when finished
                if (currentProgress - lastReportedProgress >= 5.0 || currentProgress >= 100.0) {
                    lastReportedProgress = currentProgress
                    
                    // Flutter MethodChannel requires UI Thread
                    withContext(Dispatchers.Main) {
                        channel.invokeMethod("transferProgress", mapOf(
                            "id" to transferId,
                            "progress" to currentProgress
                        ))
                    }
                }
            }
        }
    }

    private fun createOutStream(dir: DocumentFile, fileName: String, mime: String, overwrite: Boolean, append: Boolean) : Pair<DocumentFile, OutputStream> {
        val outStream: OutputStream
        val newFile: DocumentFile
        if (overwrite || append) {
            val curFile = dir.findFile(fileName)
            newFile = curFile ?: dir.createFile(mime, fileName) ?: throw Exception("File creation failed at $fileName (createOutStream, overwrite=$overwrite, append=$append)")
            outStream = context.contentResolver.openOutputStream(newFile.uri, if (append) "wa" else "wt")
                ?: throw Exception("Stream creation failed at $fileName (createOutStream, overwrite=$overwrite, append=$append")
        } else {
            newFile = dir.createFile(mime, fileName)
                ?: throw Exception("File creation failed at $fileName (createOutStream, overwrite=0")
            outStream = context.contentResolver.openOutputStream(newFile.uri)
                ?: throw Exception("Stream creation failed at $fileName (createOutStream, overwrite=0")
        }
        return Pair(newFile, outStream)
    }
}
