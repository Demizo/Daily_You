import 'package:daily_you/config_manager.dart';
import 'package:flutter/material.dart';

class MoodIcon extends StatefulWidget {
  final int? moodValue;
  final double size;

  const MoodIcon({
    super.key,
    this.moodValue,
    this.size = 20,
  });

  @override
  State<MoodIcon> createState() => _MoodIconState();
}

class _MoodIconState extends State<MoodIcon> {
  @override
  Widget build(BuildContext context) {
    String? moodIcon;
    if (ConfigManager.moodValueFieldMapping[widget.moodValue] != null) {
      moodIcon = ConfigManager()
          .getField(ConfigManager.moodValueFieldMapping[widget.moodValue]!);
    }
    return Text(
      moodIcon ?? '🫥',
      style: TextStyle(fontSize: widget.size),
    );
  }
}
