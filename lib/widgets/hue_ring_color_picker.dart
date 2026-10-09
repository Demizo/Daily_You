// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:material_ui/material_ui.dart';

class HueRingColorPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const HueRingColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  State<HueRingColorPicker> createState() => _HueRingColorPickerState();
}

class _HueRingColorPickerState extends State<HueRingColorPicker> {
  static const double _ringSize = 250;
  static const double _ringStrokeWidth = 20;

  late HSVColor _hsvColor = HSVColor.fromColor(widget.color);
  late final TextEditingController _hexController =
      TextEditingController(text: _hexOf(widget.color));

  static String _hexOf(Color color) =>
      (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

  @override
  void didUpdateWidget(HueRingColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color.toARGB32() != _hsvColor.toColor().toARGB32()) {
      _hsvColor = HSVColor.fromColor(widget.color);
      _hexController.text = _hexOf(widget.color);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _pickHsv(HSVColor hsvColor) {
    setState(() => _hsvColor = hsvColor);
    _hexController.text = _hexOf(hsvColor.toColor());
    widget.onColorChanged(hsvColor.toColor());
  }

  void _enterHex(String hex) {
    if (hex.length != 6) return;
    final color = Color(0xFF000000 | int.parse(hex, radix: 16));
    setState(() => _hsvColor = HSVColor.fromColor(color));
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              SizedBox(
                width: _ringSize,
                height: _ringSize,
                child: ColorPickerHueRing(
                  _hsvColor,
                  _pickHsv,
                  strokeWidth: _ringStrokeWidth,
                ),
              ),
              SizedBox(
                width: _ringSize / 1.6,
                height: _ringSize / 1.6,
                child: ColorPickerArea(_hsvColor, _pickHsv, PaletteType.hsv),
              ),
            ],
          ),
        ),
        Row(
          spacing: 16,
          children: [
            ColorIndicator(_hsvColor),
            Expanded(
              child: TextField(
                controller: _hexController,
                onChanged: _enterHex,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                ],
                decoration: const InputDecoration(
                  prefixText: '#',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
