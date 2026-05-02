import 'package:daily_you/models/entry.dart';

class Flashback {
  final String title;
  final List<Entry> entries;
  final List<String> entryLabels;
  final bool isOnThisDay;

  const Flashback({
    required this.title,
    required this.entries,
    required this.entryLabels,
    this.isOnThisDay = false,
  });

  bool get isMultiEntry => entries.length > 1;

  Entry get firstEntry => entries.first;
}
