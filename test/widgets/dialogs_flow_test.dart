// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/song.dart';
import 'package:daily_you/utils/location_service.dart';
import 'package:daily_you/widgets/add_song_dialog.dart';
import 'package:daily_you/widgets/location_picker_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  Widget testApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('AddSongDialog Flow', () {
    testWidgets('shows Add Song dialog with editable fields', (tester) async {
      await tester.pumpWidget(
        testApp(const AddSongDialog()),
      );

      expect(find.text('Add Song'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4)); // URL, Title, Artist, Album
      expect(find.text('Import Local Audio File'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('populates fields and shows Edit Song title in edit mode',
        (tester) async {
      final existingSong = EntrySong(
        id: 1,
        entryId: 42,
        videoId: 'abc12345678',
        url: 'https://www.youtube.com/watch?v=abc12345678',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        timeCreate: DateTime.now(),
      );

      await tester.pumpWidget(
        testApp(AddSongDialog(initialSong: existingSong)),
      );

      expect(find.text('Edit Song'), findsOneWidget);
      expect(find.text('Bohemian Rhapsody'), findsWidgets);
      expect(find.text('Queen'), findsWidgets);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('LocationPickerDialog Flow', () {
    tearDown(() {
      LocationService.instance.nativeLocationOverride = null;
    });

    testWidgets('shows Location dialog with editable coordinates and GPS button',
        (tester) async {
      await tester.pumpWidget(
        testApp(const LocationPickerDialog()),
      );

      expect(find.text('Set Location'), findsOneWidget);
      expect(find.text('Use Current Location (GPS)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('auto-fetches GPS location when button is pressed',
        (tester) async {
      LocationService.instance.nativeLocationOverride = () async => {
            'latitude': 40.7128,
            'longitude': -74.0060,
          };

      await tester.pumpWidget(
        testApp(const LocationPickerDialog()),
      );

      await tester.tap(find.text('Use Current Location (GPS)'));
      await tester.pumpAndSettle();

      expect(find.text('40.712800'), findsOneWidget);
      expect(find.text('-74.006000'), findsOneWidget);
    });
  });
}
