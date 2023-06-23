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
    String moodIcon;
    switch (widget.moodValue) {
      case 2:
        moodIcon = '😌';
        break;
      case 1:
        moodIcon = '🙂';
        break;
      case 0:
        moodIcon = '😐';
        break;
      case -1:
        moodIcon = '😕';
        break;
      case -2:
        moodIcon = '😔';
        break;
      default:
        moodIcon = '🫥';
        break;
    }
    return Text(
      moodIcon,
      style: TextStyle(fontSize: widget.size),
    );
  }
}
