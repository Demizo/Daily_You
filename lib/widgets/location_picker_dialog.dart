// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/location.dart';
import 'package:daily_you/utils/map_tile_service.dart';
import 'package:daily_you/utils/network_gate.dart';
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

  bool _isSearching = false;
  List<MapSearchResult> _searchResults = const [];

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

  Future<void> _searchPlace() async {
    final query = _placeController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await MapTileService.instance.searchPlace(query);
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults = results;
      });
    }
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
              decoration: InputDecoration(
                labelText: 'Place Name',
                hintText: 'e.g. Central Park, Home, Cafe',
                border: const OutlineInputBorder(),
                suffixIcon: NetworkGate.isNetworkAllowed
                    ? (_isSearching
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search_rounded),
                            tooltip: 'Search place online',
                            onPressed: _searchPlace,
                          ))
                    : null,
              ),
              onSubmitted: (_) {
                if (NetworkGate.isNetworkAllowed) _searchPlace();
              },
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final res = _searchResults[index];
                    return ListTile(
                      dense: true,
                      title: Text(res.name, maxLines: 1),
                      subtitle: Text(res.address,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        setState(() {
                          _placeController.text = res.name;
                          _latController.text = res.latitude.toStringAsFixed(6);
                          _lngController.text = res.longitude.toStringAsFixed(6);
                          _searchResults = const [];
                        });
                      },
                    );
                  },
                ),
              ),
            ],
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
