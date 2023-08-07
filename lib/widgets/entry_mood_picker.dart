import 'package:flutter/material.dart';
import 'package:daily_you/widgets/mood_icon.dart';

class EntryMoodPicker extends StatefulWidget {
  final int? moodValue;
  final String date;
  final ValueChanged<int?> onChangedMood;

  const EntryMoodPicker(
      {super.key,
      required this.date,
      this.moodValue,
      required this.onChangedMood});

  @override
  State<EntryMoodPicker> createState() => _EntryMoodPickerState();
}

class _EntryMoodPickerState extends State<EntryMoodPicker> {
  late int? _mood = widget.moodValue;

  Widget moodOption(int index) {
    return GestureDetector(
      child: Column(
        children: [
          MoodIcon(moodValue: index, size: 24),
          SizedBox(
            height: 24,
            child: Radio(
              value: index,
              groupValue: _mood,
              onChanged: updateMood,
              toggleable: true,
            ),
          ),
        ],
      ),
      onTap: () => updateMood(index),
    );
  }

  void updateMood(int? value) {
    if (value == _mood) {
      value = null;
    }
    setState((() => _mood = value));
    widget.onChangedMood(_mood);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Row(
            children: [
              Text(
                widget.date,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              moodOption(-2),
              moodOption(-1),
              moodOption(0),
              moodOption(1),
              moodOption(2),
            ],
          ),
        ]),
      ),
    );
  }
}
