// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:math' as math;

import 'package:daily_you/models/location.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMapPreviewWidget extends StatelessWidget {
  final EntryLocation location;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final bool isEditable;

  const LocationMapPreviewWidget({
    super.key,
    required this.location,
    this.onTap,
    this.onEdit,
    this.onRemove,
    this.isEditable = true,
  });

  String? _getTileUrl(double lat, double lon) {
    if (!NetworkGate.isNetworkAllowed) return null;
    const zoom = 15;
    final n = 1 << zoom;
    final x = ((lon + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
    return 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
  }

  Future<void> _openExternalMap() async {
    final lat = location.latitude;
    final lon = location.longitude;
    if (lat != null && lon != null) {
      final uri = Uri.parse(
          'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=16/$lat/$lon');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lat = location.latitude;
    final lon = location.longitude;
    final hasCoords = lat != null && lon != null;
    final tileUrl = hasCoords ? _getTileUrl(lat, lon) : null;

    final placeLabel = location.placeName != null && location.placeName!.trim().isNotEmpty
        ? location.placeName!.trim()
        : (hasCoords ? 'Pinned Location' : 'Location');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap ?? (hasCoords ? _openExternalMap : null),
        child: SizedBox(
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background (Tile Image or Blueprint Grid)
              if (tileUrl != null)
                Image.network(
                  tileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildBlueprintBackground(theme),
                )
              else
                _buildBlueprintBackground(theme),

              // 2. Center Pin Marker (if coordinates present)
              if (hasCoords)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // 3. Top-Left Place Name Pill
              Positioned(
                top: 10,
                left: 10,
                right: isEditable ? 96 : 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(225),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          placeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Top-Right Actions
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEditable && onEdit != null)
                      _buildActionCircle(
                        icon: Icons.edit_rounded,
                        tooltip: 'Edit location',
                        onTap: onEdit!,
                        theme: theme,
                      ),
                    if (isEditable && onRemove != null) ...[
                      const SizedBox(width: 4),
                      _buildActionCircle(
                        icon: Icons.close_rounded,
                        tooltip: 'Remove location',
                        onTap: onRemove!,
                        theme: theme,
                      ),
                    ],
                    if (!isEditable && hasCoords)
                      _buildActionCircle(
                        icon: Icons.open_in_new_rounded,
                        tooltip: 'Open in Map',
                        onTap: _openExternalMap,
                        theme: theme,
                      ),
                  ],
                ),
              ),

              // 5. Bottom-Left Coordinates / Offline Pill
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(210),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!NetworkGate.isNetworkAllowed) ...[
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        hasCoords
                            ? '${lat.toStringAsFixed(4)}°, ${lon.toStringAsFixed(4)}°'
                            : 'No coordinates',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: theme.colorScheme.surface.withAlpha(225),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(icon, size: 16, color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildBlueprintBackground(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(160),
      child: CustomPaint(
        painter: _MapGridPainter(
          gridColor: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final Color gridColor;

  _MapGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}
