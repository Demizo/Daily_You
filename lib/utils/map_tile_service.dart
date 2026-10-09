// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:flutter/foundation.dart';

enum MapStyleProvider {
  carto,
  mapTiler,
  stadia,
  mapbox;

  static MapStyleProvider fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'maptiler':
        return MapStyleProvider.mapTiler;
      case 'stadia':
        return MapStyleProvider.stadia;
      case 'mapbox':
        return MapStyleProvider.mapbox;
      default:
        return MapStyleProvider.carto;
    }
  }
}

class MapSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const MapSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSearchResult &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      name.hashCode ^ address.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}

typedef HttpGetHandler = Future<({int statusCode, Uint8List body})?> Function(
    Uri uri);

class MapTileService {
  static final MapTileService instance = MapTileService();

  @visibleForTesting
  HttpGetHandler? httpGetOverride;

  Future<({int statusCode, Uint8List body})?> _httpGet(Uri uri) async {
    if (httpGetOverride != null) {
      return await httpGetOverride!(uri);
    }
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'DailyYou/1.0 (Android)');
      final response = await request.close().timeout(const Duration(seconds: 6));
      final bytes = await response.fold<List<int>>(
          <int>[], (buffer, chunk) => buffer..addAll(chunk));
      client.close();
      return (
        statusCode: response.statusCode,
        body: Uint8List.fromList(bytes),
      );
    } catch (_) {
      return null;
    }
  }

  String getStyleUrl({
    MapStyleProvider? provider,
    bool isDark = false,
  }) {
    final activeProvider = provider ??
        MapStyleProvider.fromKey(
            ConfigProvider.instance.get(Settings.mapStyleProvider));

    switch (activeProvider) {
      case MapStyleProvider.carto:
        final style =
            isDark ? 'dark-matter-gl-style' : 'voyager-gl-style';
        return 'https://basemaps.cartocdn.com/gl/$style/style.json';

      case MapStyleProvider.mapTiler:
        final key = ConfigProvider.instance.get(Settings.mapTilerKey);
        final style = isDark ? 'streets-v4-dark' : 'streets-v4';
        return 'https://api.maptiler.com/maps/$style/style.json?key=$key';

      case MapStyleProvider.stadia:
        final key = ConfigProvider.instance.get(Settings.stadiaKey);
        final style = isDark ? 'alidade_smooth_dark' : 'alidade_smooth';
        final query = key.isNotEmpty ? '?api_key=$key' : '';
        return 'https://tiles.stadiamaps.com/styles/$style.json$query';

      case MapStyleProvider.mapbox:
        final key = ConfigProvider.instance.get(Settings.mapboxKey);
        final style = isDark ? 'dark-v10' : 'streets-v11';
        return 'https://api.mapbox.com/styles/v1/mapbox/$style?access_token=$key';
    }
  }

  Future<List<MapSearchResult>> searchPlace(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];

    if (!NetworkGate.isNetworkAllowed) {
      return const [];
    }

    final mapTilerKey = ConfigProvider.instance.get(Settings.mapTilerKey);

    // 1. MapTiler geocoding if key configured
    if (mapTilerKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
            'https://api.maptiler.com/geocoding/${Uri.encodeComponent(clean)}.json?key=$mapTilerKey&limit=5');
        final res = await _httpGet(uri);
        if (res != null && res.statusCode == 200) {
          final json = jsonDecode(utf8.decode(res.body)) as Map<String, dynamic>;
          final features = json['features'] as List<dynamic>?;
          if (features != null && features.isNotEmpty) {
            final results = <MapSearchResult>[];
            for (final f in features) {
              final center = f['center'] as List<dynamic>;
              final placeName = f['place_name'] as String? ?? clean;
              final text = f['text'] as String? ?? placeName;
              results.add(MapSearchResult(
                name: text,
                address: placeName,
                latitude: (center[1] as num).toDouble(),
                longitude: (center[0] as num).toDouble(),
              ));
            }
            if (results.isNotEmpty) return results;
          }
        }
      } catch (_) {}
    }

    // 2. Default OpenStreetMap Nominatim keyless search
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(clean)}&format=json&limit=5');
      final res = await _httpGet(uri);
      if (res != null && res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.body)) as List<dynamic>;
        final results = <MapSearchResult>[];
        for (final item in list) {
          final displayName = item['display_name'] as String? ?? clean;
          final parts = displayName.split(',');
          final name = parts.first.trim();
          final address =
              parts.length > 1 ? parts.sublist(1).join(',').trim() : displayName;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            results.add(MapSearchResult(
              name: name,
              address: address,
              latitude: lat,
              longitude: lon,
            ));
          }
        }
        return results;
      }
    } catch (_) {}

    return const [];
  }
}
