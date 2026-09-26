package com.demizo.daily_you.backup_crypto

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.RandomAccessFile
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

private const val TAG_LENGTH_BYTES = 16
private const val TAG_LENGTH_BITS = TAG_LENGTH_BYTES * 8
private const val NONCE_LENGTH_BYTES = 12
private const val BASE_NONCE_LENGTH_BYTES = 4

class BackupCryptoPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val cancelledRequests = ConcurrentHashMap<String, AtomicBoolean>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "backup_crypto")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "encryptBody" -> runBody(call, result, encrypt = true)
            "decryptBody" -> runBody(call, result, encrypt = false)
            "cancel" -> {
                cancelledRequests[call.argument<String>("requestId")!!]?.set(true)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun runBody(call: MethodCall, result: Result, encrypt: Boolean) {
        val inputPath = call.argument<String>("inputPath")!!
        val outputPath = call.argument<String>("outputPath")!!
        val key = call.argument<ByteArray>("key")!!
        val baseNonce = call.argument<ByteArray>("baseNonce")!!
        val chunkPlainSize = (call.argument<Number>("chunkPlainSize")!!).toLong()
        val totalPlainLength = (call.argument<Number>("totalPlainLength")!!).toLong()
        val headerLength = (call.argument<Number>("headerLength")!!).toLong()
        val requestId = call.argument<String>("requestId")!!
        val onDiskChunkSize = chunkPlainSize + TAG_LENGTH_BYTES
        // Registered before launching: a "cancel" call right after this one
        // is guaranteed to find it, since MethodChannel calls on one channel
        // are handled in send order.
        val cancelled = cancelledRequests.getOrPut(requestId) { AtomicBoolean(false) }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val secretKey = SecretKeySpec(key, "AES")
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                var processed = 0L
                var lastReportedPercent = -1

                RandomAccessFile(inputPath, "r").use { input ->
                    RandomAccessFile(outputPath, "rw").use { output ->
                        var chunkIndex = 0L
                        while (processed < totalPlainLength) {
                            if (cancelled.get()) {
                                withContext(Dispatchers.Main) {
                                    result.error("CANCELLED", "Cancelled", null)
                                }
                                return@launch
                            }

                            val plainLength = minOf(chunkPlainSize, totalPlainLength - processed)
                            val nonce = chunkNonce(baseNonce, chunkIndex)
                            val params = GCMParameterSpec(TAG_LENGTH_BITS, nonce)

                            if (encrypt) {
                                val plainBytes = ByteArray(plainLength.toInt())
                                input.seek(chunkIndex * chunkPlainSize)
                                input.readFully(plainBytes)

                                cipher.init(Cipher.ENCRYPT_MODE, secretKey, params)
                                val cipherAndTag = cipher.doFinal(plainBytes)

                                output.seek(headerLength + chunkIndex * onDiskChunkSize)
                                output.write(cipherAndTag)
                            } else {
                                val cipherAndTag = ByteArray(plainLength.toInt() + TAG_LENGTH_BYTES)
                                input.seek(headerLength + chunkIndex * onDiskChunkSize)
                                input.readFully(cipherAndTag)

                                cipher.init(Cipher.DECRYPT_MODE, secretKey, params)
                                val plainBytes = cipher.doFinal(cipherAndTag)

                                output.seek(chunkIndex * chunkPlainSize)
                                output.write(plainBytes)
                            }

                            processed += plainLength
                            chunkIndex += 1

                            val percent = ((processed.toDouble() / totalPlainLength) * 100).toInt()
                            if (percent != lastReportedPercent) {
                                lastReportedPercent = percent
                                withContext(Dispatchers.Main) {
                                    channel.invokeMethod(
                                        "progress",
                                        mapOf("requestId" to requestId, "percent" to percent)
                                    )
                                }
                            }
                        }
                    }
                }

                withContext(Dispatchers.Main) { result.success(null) }
            } catch (err: AEADBadTagException) {
                withContext(Dispatchers.Main) { result.error("DECRYPTION_FAILED", err.message, null) }
            } catch (err: Exception) {
                withContext(Dispatchers.Main) { result.error("PluginError", err.message, null) }
            } finally {
                cancelledRequests.remove(requestId)
            }
        }
    }

    // Matches BackupEncryption._chunkNonce in lib/utils/backup_encryption.dart:
    // 12-byte nonce = 4-byte baseNonce || 8-byte big-endian chunkIndex.
    private fun chunkNonce(baseNonce: ByteArray, chunkIndex: Long): ByteArray {
        val nonce = ByteArray(NONCE_LENGTH_BYTES)
        baseNonce.copyInto(nonce, 0, 0, BASE_NONCE_LENGTH_BYTES)
        for (i in 0 until 8) {
            nonce[BASE_NONCE_LENGTH_BYTES + i] = ((chunkIndex shr (8 * (7 - i))) and 0xFF).toByte()
        }
        return nonce
    }
}
