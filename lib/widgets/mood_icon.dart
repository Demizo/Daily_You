import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';

class MoodIcon extends StatefulWidget {
  final int? moodValue;
  final double size;
  final bool allowScaling;

  const MoodIcon({
    super.key,
    this.moodValue,
    this.size = 20,
    this.allowScaling = true,
  });

  @override
  State<MoodIcon> createState() => _MoodIconState();

  static String getMoodIcon(int? moodValue) {
    String? moodIcon;
    if (ConfigProvider.moodValueFieldMapping[moodValue] != null) {
      moodIcon = ConfigProvider.instance
          .get(ConfigProvider.moodValueFieldMapping[moodValue]!);
    }
    return moodIcon ?? ConfigProvider.instance.get(ConfigKey.noMoodIcon);
  }
}

class _MoodIconState extends State<MoodIcon> {
  @override
  Widget build(BuildContext context) {
    return Text(
      MoodIcon.getMoodIcon(widget.moodValue),
      style: TextStyle(fontSize: widget.size),
      textScaler: widget.allowScaling ? null : TextScaler.noScaling,
    );
  }
}
