// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/location.dart';
import 'package:daily_you/utils/location_service.dart';
import 'package:daily_you/utils/map_tile_service.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/widgets/location_map_preview_widget.dart';
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
  bool _isFetchingGps = false;
  String? _errorMessage;
  List<MapSearchResult> _searchResults = const [];

  @override
  void initState() {
    super.initState();
    _placeController = TextEditingController(
        text: widget.initialLocation?.placeName ?? '');
    _latController = TextEditingController(
        text: widget.initialLocation?.latitude?.toStringAsFixed(6) ?? '');
    _lngController = TextEditingController(
        text: widget.initialLocation?.longitude?.toStringAsFixed(6) ?? '');

    _placeController.addListener(() => setState(() {}));
    _latController.addListener(() => setState(() {}));
    _lngController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _placeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingGps = true;
      _errorMessage = null;
    });

    try {
      final loc = await LocationService.instance.fetchCurrentLocation(
        entryId: widget.initialLocation?.entryId ?? -1,
      );
      if (loc != null && mounted) {
        setState(() {
          _latController.text = loc.latitude?.toStringAsFixed(6) ?? '';
          _lngController.text = loc.longitude?.toStringAsFixed(6) ?? '';
          if (loc.placeName != null && loc.placeName!.isNotEmpty) {
            _placeController.text = loc.placeName!;
          } else if (_placeController.text.trim().isEmpty) {
            _placeController.text = 'Current Location';
          }
          _isFetchingGps = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'GPS unavailable or permission denied. Please enter coordinates manually.';
            _isFetchingGps = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Location error: $e';
          _isFetchingGps = false;
        });
      }
    }
  }

  Future<void> _searchPlace() async {
    final query = _placeController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });
    try {
      final results = await MapTileService.instance.searchPlace(query);
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = results;
          if (results.isEmpty) {
            _errorMessage = 'No places found matching "$query"';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Search error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNetwork = NetworkGate.isNetworkAllowed;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final place = _placeController.text.trim();
    final hasValidCoords = lat != null && lng != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Set Location'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Preview Card
            if (hasValidCoords || place.isNotEmpty) ...[
              LocationMapPreviewWidget(
                location: EntryLocation(
                  id: null,
                  entryId: -1,
                  latitude: hasValidCoords ? lat : null,
                  longitude: hasValidCoords ? lng : null,
                  placeName: place.isNotEmpty ? place : null,
                  timeCreate: DateTime.now(),
                ),
                isEditable: false,
              ),
              const SizedBox(height: 12),
            ],

            // Auto-fetch GPS button
            FilledButton.tonalIcon(
              icon: _isFetchingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(_isFetchingGps ? 'Locating device…' : 'Use Current Location (GPS)'),
              onPressed: _isFetchingGps ? null : _fetchCurrentLocation,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _placeController,
              decoration: InputDecoration(
                labelText: 'Place Name / Address',
                hintText: 'e.g. Central Park, Home, Cafe',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.place_rounded),
                suffixIcon: hasNetwork
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
                if (hasNetwork) _searchPlace();
              },
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
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
                      isDense: true,
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
                      isDense: true,
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
            final placeStr = _placeController.text.trim();
            final latVal = double.tryParse(_latController.text.trim());
            final lngVal = double.tryParse(_lngController.text.trim());

            if (placeStr.isEmpty && latVal == null && lngVal == null) {
              Navigator.of(context).pop();
              return;
            }

            final loc = EntryLocation(
              entryId: widget.initialLocation?.entryId ?? -1,
              placeName: placeStr.isNotEmpty ? placeStr : null,
              latitude: latVal,
              longitude: lngVal,
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
