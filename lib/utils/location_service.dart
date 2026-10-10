// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/location.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef LocationNativeHandler = Future<Map<String, dynamic>?> Function();
typedef ReverseGeocodeHandler = Future<String?> Function(double lat, double lon);

class LocationService {
  static final LocationService instance = LocationService();

  static const MethodChannel _channel =
      MethodChannel('com.traxdinosaur.dailyyou/location');

  @visibleForTesting
  LocationNativeHandler? nativeLocationOverride;

  @visibleForTesting
  ReverseGeocodeHandler? reverseGeocodeOverride;

  /// Fetches current device GPS / Network location.
  Future<EntryLocation?> fetchCurrentLocation({int entryId = -1}) async {
    Map<String, dynamic>? data;

    if (nativeLocationOverride != null) {
      data = await nativeLocationOverride!();
    } else {
      if (Platform.isAndroid) {
        try {
          final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation');
          if (res != null) {
            data = Map<String, dynamic>.from(res);
          }
        } catch (_) {}
      }
    }

    if (data == null) return null;

    final lat = (data['latitude'] as num?)?.toDouble();
    final lon = (data['longitude'] as num?)?.toDouble();

    if (lat == null || lon == null) return null;

    String? placeName;
    if (NetworkGate.isNetworkAllowed) {
      placeName = await reverseGeocode(lat, lon);
    }

    return EntryLocation(
      entryId: entryId,
      latitude: lat,
      longitude: lon,
      placeName: placeName,
      timeCreate: DateTime.now(),
    );
  }

  /// Reverse geocodes coordinates to a human-readable place name via OpenStreetMap Nominatim.
  Future<String?> reverseGeocode(double lat, double lon) async {
    if (reverseGeocodeOverride != null) {
      return await reverseGeocodeOverride!(lat, lon);
    }

    if (!NetworkGate.isNetworkAllowed) return null;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
      final request = await client.getUrl(uri);
      request.headers.set(
          HttpHeaders.userAgentHeader, 'DailyYou/1.0 (Android)');
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = await utf8.decodeStream(response);
        final json = jsonDecode(body) as Map<String, dynamic>;
        final displayName = json['display_name'] as String?;
        if (displayName != null) {
          final parts = displayName.split(',');
          if (parts.length > 2) {
            return '${parts[0].trim()}, ${parts[1].trim()}';
          }
          return displayName;
        }
      }
    } catch (_) {}

    return null;
  }
}
