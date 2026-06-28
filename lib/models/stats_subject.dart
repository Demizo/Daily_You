import 'package:daily_you/models/tag.dart';

sealed class StatsSubject {
  const StatsSubject();

  String toConfigString();

  static StatsSubject fromConfigString(String? configString, List<Tag> allTags) {
    if (configString == null || configString == 'mood') {
      return const MoodSubject();
    }
    final separatorIndex = configString.indexOf(':');
    if (separatorIndex < 0) return const MoodSubject();
    final type = configString.substring(0, separatorIndex);
    final id = int.tryParse(configString.substring(separatorIndex + 1));
    if (id == null) return const MoodSubject();
    final tag = allTags.where((t) => t.id == id).firstOrNull;
    if (tag == null) return const MoodSubject();
    return switch (type) {
      'label' => LabelSubject(tag),
      'tracker' => TrackerSubject(tag),
      _ => const MoodSubject(),
    };
  }
}

final class MoodSubject extends StatsSubject {
  const MoodSubject();
  @override
  String toConfigString() => 'mood';
}

final class LabelSubject extends StatsSubject {
  final Tag tag;
  const LabelSubject(this.tag);
  @override
  String toConfigString() => 'label:${tag.id}';
}

final class TrackerSubject extends StatsSubject {
  final Tag tag;
  const TrackerSubject(this.tag);
  @override
  String toConfigString() => 'tracker:${tag.id}';
}
