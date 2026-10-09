// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/map_tile_service.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('MapTileService (F19)', () {
    setUp(() {
      NetworkGate.debugOverrideCompiledIn = true;
    });

    tearDown(() {
      MapTileService.instance.httpGetOverride = null;
      NetworkGate.debugOverrideCompiledIn = null;
    });

    test('generates CARTO keyless style URLs', () {
      final lightUrl = MapTileService.instance.getStyleUrl(
        provider: MapStyleProvider.carto,
        isDark: false,
      );
      expect(lightUrl,
          'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json');

      final darkUrl = MapTileService.instance.getStyleUrl(
        provider: MapStyleProvider.carto,
        isDark: true,
      );
      expect(darkUrl,
          'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json');
    });

    test('generates MapTiler and Stadia style URLs with keys', () async {
      await ConfigProvider.instance.set(Settings.mapTilerKey, 'maptiler123');
      final mapTilerUrl = MapTileService.instance.getStyleUrl(
        provider: MapStyleProvider.mapTiler,
        isDark: false,
      );
      expect(mapTilerUrl, contains('key=maptiler123'));

      await ConfigProvider.instance.set(Settings.stadiaKey, 'stadia456');
      final stadiaUrl = MapTileService.instance.getStyleUrl(
        provider: MapStyleProvider.stadia,
        isDark: true,
      );
      expect(stadiaUrl, contains('api_key=stadia456'));
    });

    test('returns empty results when network access is disabled', () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, false);

      final results = await MapTileService.instance.searchPlace('Paris');
      expect(results, isEmpty);
    });

    test('parses Nominatim geocoding response when network is allowed', () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, true);
      await ConfigProvider.instance.set(Settings.mapTilerKey, '');

      MapTileService.instance.httpGetOverride = (uri) async {
        final mockJson = jsonEncode([
          {
            'display_name': 'Eiffel Tower, Champ de Mars, Paris, France',
            'lat': '48.8584',
            'lon': '2.2945',
          }
        ]);
        return (
          statusCode: 200,
          body: Uint8List.fromList(utf8.encode(mockJson)),
        );
      };

      final results = await MapTileService.instance.searchPlace('Eiffel');
      expect(results.length, 1);
      expect(results.first.name, 'Eiffel Tower');
      expect(results.first.latitude, closeTo(48.8584, 0.0001));
      expect(results.first.longitude, closeTo(2.2945, 0.0001));
    });
  });
}
