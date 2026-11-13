// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/widgets/mood_option.dart';
import 'package:material_ui/material_ui.dart';

class EntryMoodPicker extends StatefulWidget {
  final int? moodValue;
  final ValueChanged<int?> onChangedMood;

  const EntryMoodPicker(
      {super.key, this.moodValue, required this.onChangedMood});

  @override
  State<EntryMoodPicker> createState() => _EntryMoodPickerState();
}

class _EntryMoodPickerState extends State<EntryMoodPicker> {
  late int? _mood = widget.moodValue;

  @override
  void didUpdateWidget(covariant EntryMoodPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moodValue != widget.moodValue) {
      setState(() => _mood = widget.moodValue);
    }
  }

  void _updateMood(int? value) {
    if (value == _mood) {
      value = null;
    }
    setState((() => _mood = value));
    widget.onChangedMood(_mood);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final mood in Mood.levels)
          MoodOption(
            mood: mood,
            isSelected: mood == _mood,
            onTap: () => _updateMood(mood),
          ),
      ],
    );
  }
}
