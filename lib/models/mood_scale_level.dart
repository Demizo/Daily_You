// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag_icon_type.dart';

const String moodScaleTable = 'mood_scale';

class MoodScaleLevelFields {
  static const String mood = 'mood';
  static const String label = 'label';
  static const String icon = 'icon';
  static const String iconType = 'icon_type';
  static const String color = 'color';
}

class MoodScaleLevel {
  final int mood;
  final String? label;
  final String? icon;
  final TagIconType iconType;
  final int? color;

  const MoodScaleLevel({
    required this.mood,
    this.label,
    this.icon,
    this.iconType = TagIconType.character,
    this.color,
  });

  bool get hasIcon => (icon ?? '').isNotEmpty;

  bool get hasTextIcon => iconType == TagIconType.character && hasIcon;

  static const _unset = Object();

  MoodScaleLevel copyWith({
    Object? label = _unset,
    Object? icon = _unset,
    TagIconType? iconType,
    Object? color = _unset,
  }) =>
      MoodScaleLevel(
        mood: mood,
        label: label == _unset ? this.label : label as String?,
        icon: icon == _unset ? this.icon : icon as String?,
        iconType: iconType ?? this.iconType,
        color: color == _unset ? this.color : color as int?,
      );

  static MoodScaleLevel fromJson(Map<String, Object?> json) => MoodScaleLevel(
        mood: json[MoodScaleLevelFields.mood] as int,
        label: json[MoodScaleLevelFields.label] as String?,
        icon: json[MoodScaleLevelFields.icon] as String?,
        iconType:
            TagIconType.fromInt(json[MoodScaleLevelFields.iconType] as int?),
        color: json[MoodScaleLevelFields.color] as int?,
      );

  Map<String, Object?> toJson() => {
        MoodScaleLevelFields.mood: mood,
        MoodScaleLevelFields.label: label,
        MoodScaleLevelFields.icon: icon,
        MoodScaleLevelFields.iconType: iconType.toInt(),
        MoodScaleLevelFields.color: color,
      };
}
