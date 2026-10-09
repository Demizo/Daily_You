// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/location.dart';
import 'package:daily_you/widgets/location_map_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LocationMapPreviewWidget displays location name and coordinates',
      (tester) async {
    final location = EntryLocation(
      id: 1,
      entryId: 1,
      latitude: 37.7749,
      longitude: -122.4194,
      placeName: 'Golden Gate Bridge',
      timeCreate: DateTime(2026, 10, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationMapPreviewWidget(
            location: location,
            isEditable: true,
            onEdit: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Golden Gate Bridge'), findsOneWidget);
    expect(find.text('37.7749°, -122.4194°'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
