// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/location.dart';
import 'package:material_ui/material_ui.dart';

class LocationPickerDialog extends StatefulWidget {
  final EntryLocation? initialLocation;

  const LocationPickerDialog({super.key, this.initialLocation});

  static Future<EntryLocation?> show(BuildContext context,
      {EntryLocation? initialLocation}) {
    return showDialog<EntryLocation>(
      context: context,
      builder: (_) =>
          LocationPickerDialog(initialLocation: initialLocation),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late TextEditingController _placeController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _placeController = TextEditingController(
        text: widget.initialLocation?.placeName ?? '');
    _latController = TextEditingController(
        text: widget.initialLocation?.latitude?.toString() ?? '');
    _lngController = TextEditingController(
        text: widget.initialLocation?.longitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _placeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.location_on_rounded),
          SizedBox(width: 8),
          Text('Set Location'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'Place Name',
                hintText: 'e.g. Central Park, Home, Cafe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '37.7749',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '-122.4194',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initialLocation != null)
          TextButton(
            onPressed: () {
              // Return a sentinel with null place and coords to clear
              Navigator.of(context).pop(EntryLocation(
                entryId: widget.initialLocation!.entryId,
                placeName: null,
                latitude: null,
                longitude: null,
                timeCreate: DateTime.now(),
              ));
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final place = _placeController.text.trim();
            final lat = double.tryParse(_latController.text.trim());
            final lng = double.tryParse(_lngController.text.trim());
            if (place.isEmpty && lat == null && lng == null) {
              Navigator.of(context).pop();
              return;
            }
            final loc = EntryLocation(
              entryId: widget.initialLocation?.entryId ?? -1,
              placeName: place.isNotEmpty ? place : null,
              latitude: lat,
              longitude: lng,
              timeCreate: DateTime.now(),
            );
            Navigator.of(context).pop(loc);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
