// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/location_service.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('LocationService', () {
    setUp(() {
      NetworkGate.debugOverrideCompiledIn = true;
    });

    tearDown(() {
      LocationService.instance.nativeLocationOverride = null;
      LocationService.instance.reverseGeocodeOverride = null;
      NetworkGate.debugOverrideCompiledIn = null;
    });

    test('returns null when native provider returns null', () async {
      LocationService.instance.nativeLocationOverride = () async => null;
      final loc = await LocationService.instance.fetchCurrentLocation();
      expect(loc, isNull);
    });

    test('fetches coordinates and reverse-geocodes place name when network allowed',
        () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, true);

      LocationService.instance.nativeLocationOverride = () async => {
            'latitude': 37.7749,
            'longitude': -122.4194,
          };

      LocationService.instance.reverseGeocodeOverride =
          (lat, lon) async => 'San Francisco, California';

      final loc = await LocationService.instance.fetchCurrentLocation(entryId: 10);
      expect(loc, isNotNull);
      expect(loc!.entryId, 10);
      expect(loc.latitude, closeTo(37.7749, 0.0001));
      expect(loc.longitude, closeTo(-122.4194, 0.0001));
      expect(loc.placeName, 'San Francisco, California');
    });

    test('fetches coordinates without reverse-geocoding when network disabled',
        () async {
      await ConfigProvider.instance.set(Settings.allowNetworkAccess, false);

      LocationService.instance.nativeLocationOverride = () async => {
            'latitude': 51.5074,
            'longitude': -0.1278,
          };

      final loc = await LocationService.instance.fetchCurrentLocation();
      expect(loc, isNotNull);
      expect(loc!.latitude, closeTo(51.5074, 0.0001));
      expect(loc.longitude, closeTo(-0.1278, 0.0001));
      expect(loc.placeName, isNull);
    });
  });
}
