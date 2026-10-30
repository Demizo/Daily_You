// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/color_swatch_row.dart';
import 'package:daily_you/widgets/icon_picker_dialog.dart';
import 'package:daily_you/widgets/mood_scale_glyph.dart';
import 'package:material_ui/material_ui.dart';

class EditMoodScale extends StatefulWidget {
  final List<MoodScaleLevel> initial;

  const EditMoodScale({super.key, required this.initial});

  @override
  State<EditMoodScale> createState() => _EditMoodScaleState();
}

class _EditMoodScaleState extends State<EditMoodScale> {
  late final List<MoodScaleLevel> _levels = [...widget.initial];
  late final List<TextEditingController> _labelControllers = [
    for (final level in _levels) TextEditingController(text: level.label ?? '')
  ];

  @override
  void dispose() {
    for (final controller in _labelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setLook(
    int position, {
    required String? icon,
    required TagIconType iconType,
    required int? color,
  }) {
    setState(() => _levels[position] = _levels[position]
        .copyWith(icon: icon, iconType: iconType, color: color));
  }

  void _applyPreset(MoodScalePreset preset) {
    setState(() {
      for (final (position, level) in preset.levels.indexed) {
        _levels[position] = _levels[position].copyWith(
          icon: level.icon,
          iconType: level.iconType,
          color: level.color,
        );
      }
    });
  }

  Future<void> _pickIcon(int position) async {
    final level = _levels[position];
    final result = await showAppDialog<IconPickerResult>(
      context: context,
      builder: (context) => IconPickerDialog(
        previewColor: level.resolvedColor(context),
        initial: (type: level.iconType, value: level.icon),
      ),
    );
    if (result == null) return;
    _setLook(position,
        icon: result.value, iconType: result.type, color: level.color);
  }

  Future<void> _pickColor(int position) async {
    final level = _levels[position];
    final result = await showAppDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: level.color != null ? Color(level.color!) : null,
        showNoneOption: true,
      ),
    );
    if (result == null) return;
    _setLook(position,
        icon: level.icon,
        iconType: level.iconType,
        color: result.color?.toARGB32());
  }

  String? _labelAt(int position) {
    final text = _labelControllers[position].text.trim();
    return text.isEmpty ? null : text;
  }

  void _save() {
    Navigator.of(context).pop([
      for (final (position, level) in _levels.indexed)
        level.copyWith(label: _labelAt(position)),
    ]);
  }

  Widget _buildPresets() {
    return Row(
      spacing: 8.0,
      children: [
        for (final preset in MoodScalePreset.values)
          Expanded(
            child: _PresetTile(
              preset: preset,
              onTap: () => _applyPreset(preset),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, AppLocalizations l10n, int position) {
    final level = _levels[position];
    final cardColor = Theme.of(context).colorScheme.surfaceContainerLowest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: () => _pickIcon(position),
                child: Card.filled(
                  margin: EdgeInsets.zero,
                  color: cardColor,
                  child: Center(
                    child: MoodScaleGlyph(level: level, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card.filled(
                margin: EdgeInsets.zero,
                color: cardColor,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      controller: _labelControllers[position],
                      maxLines: 1,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: Mood.defaultLabel(position, l10n),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ColorSwatchButton(
              color: level.resolvedColor(context),
              onTap: () => _pickColor(position),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth - 80).clamp(280.0, 400.0);
    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPresets(),
                      const SizedBox(height: 12),
                      for (var position = _levels.length - 1;
                          position >= 0;
                          position--)
                        _buildRow(context, l10n, position),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: Text(
                      MaterialLocalizations.of(context).okButtonLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final MoodScalePreset preset;
  final VoidCallback onTap;

  const _PresetTile({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FittedBox(
            child: Row(
              children: [
                for (final level in preset.levels)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: MoodScaleGlyph(
                      level: level,
                      size: 18,
                      allowScaling: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
