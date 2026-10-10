// Behavior based on DenserMeerkat/June (GPL-3.0)
package com.traxdinosaur.dailyyou

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.content.Intent
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.Manifest

class MainActivity: FlutterFragmentActivity() {
  private val SECURITY_CHANNEL = "com.traxdinosaur.dailyyou/security"
  private val LOCATION_CHANNEL = "com.traxdinosaur.dailyyou/location"
  private val LOCATION_PERMISSION_REQUEST_CODE = 1001

  private var pendingLocationResult: MethodChannel.Result? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "setSecureMode" -> {
          val secure = call.argument<Boolean>("secure") ?: false
          if (secure) {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
          } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          }
          result.success(true)
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "getCurrentLocation" -> {
          fetchLocation(result)
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun fetchLocation(result: MethodChannel.Result) {
    val fineGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    val coarseGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    if (!fineGranted && !coarseGranted) {
      pendingLocationResult = result
      ActivityCompat.requestPermissions(
        this,
        arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
        LOCATION_PERMISSION_REQUEST_CODE
      )
      return
    }

    retrieveBestLocation(result)
  }

  private fun retrieveBestLocation(result: MethodChannel.Result) {
    val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
    if (lm == null) {
      result.error("LOCATION_UNAVAILABLE", "LocationManager not available", null)
      return
    }

    val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
      .filter { lm.isProviderEnabled(it) }

    if (providers.isEmpty()) {
      result.error("LOCATION_DISABLED", "Location providers are disabled", null)
      return
    }

    var bestLocation: Location? = null
    for (p in providers) {
      try {
        val l = lm.getLastKnownLocation(p) ?: continue
        if (bestLocation == null || l.accuracy < bestLocation.accuracy) {
          bestLocation = l
        }
      } catch (_: SecurityException) {}
    }

    if (bestLocation != null) {
      result.success(mapOf(
        "latitude" to bestLocation.latitude,
        "longitude" to bestLocation.longitude,
        "accuracy" to bestLocation.accuracy.toDouble()
      ))
      return
    }

    // Try single update
    val provider = providers.first()
    val handler = Handler(Looper.getMainLooper())
    var completed = false

    val listener = object : LocationListener {
      override fun onLocationChanged(loc: Location) {
        if (!completed) {
          completed = true
          lm.removeUpdates(this)
          result.success(mapOf(
            "latitude" to loc.latitude,
            "longitude" to loc.longitude,
            "accuracy" to loc.accuracy.toDouble()
          ))
        }
      }
      override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
      override fun onProviderEnabled(provider: String) {}
      override fun onProviderDisabled(provider: String) {}
    }

    try {
      lm.requestSingleUpdate(provider, listener, Looper.getMainLooper())
      handler.postDelayed({
        if (!completed) {
          completed = true
          lm.removeUpdates(listener)
          result.error("TIMEOUT", "Location request timed out", null)
        }
      }, 8000)
    } catch (e: Exception) {
      result.error("LOCATION_ERROR", e.message, null)
    }
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
      val res = pendingLocationResult
      pendingLocationResult = null
      if (res != null) {
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          retrieveBestLocation(res)
        } else {
          res.error("PERMISSION_DENIED", "Location permission was denied", null)
        }
      }
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
  }
}
