// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/edit_mood_scale.dart';
import 'package:daily_you/widgets/mood_scale_glyph.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MoodScaleSetting extends StatelessWidget {
  static const double _circleSize = 40;
  static const double _ringWidth = 3;

  const MoodScaleSetting({super.key});

  Future<void> _edit(BuildContext context) async {
    final provider = context.read<MoodScaleProvider>();
    final edited = await showAppDialog<List<MoodScaleLevel>>(
      context: context,
      builder: (_) => EditMoodScale(initial: provider.levels),
    );
    if (edited != null) await provider.save(edited);
  }

  Widget _circle(BuildContext context, MoodScaleLevel level) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _circleSize),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: level.hasTextIcon
                  ? Border.all(
                      color: level.resolvedColor(context),
                      width: _ringWidth,
                    )
                  : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: MoodScaleGlyph(
                level: level,
                size: 24,
                allowScaling: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = context.watch<MoodScaleProvider>().levels;

    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _edit(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              for (final level in levels)
                Expanded(child: _circle(context, level)),
            ],
          ),
        ),
      ),
    );
  }
}
