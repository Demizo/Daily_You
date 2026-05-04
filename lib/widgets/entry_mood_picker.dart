import 'package:daily_you/widgets/material_shapes.dart';
import 'package:daily_you/widgets/punch_scale.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/mood_icon.dart';

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

  Widget _moodOption(int index) {
    final isSelected = index == _mood;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _updateMood(index),
      child: SizedBox(
        width: 52,
        height: 52,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          builder: (context, progress, child) {
            return CustomPaint(
              painter: MorphingBurstPainter(
                progress: progress,
                color: Color.lerp(
                  cs.surfaceContainerLow,
                  cs.surfaceContainerLowest,
                  progress,
                )!,
              ),
              child: Center(child: child),
            );
          },
          child: PunchScale(
            key: ValueKey(index),
            trigger: isSelected,
            child: Opacity(
                opacity: isSelected ? 1.0 : 0.6,
                child: MoodIcon(moodValue: index, size: 24)),
          ),
        ),
      ),
    );
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
        _moodOption(-2),
        _moodOption(-1),
        _moodOption(0),
        _moodOption(1),
        _moodOption(2),
      ],
    );
  }
}
