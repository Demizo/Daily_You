// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/layouts/wide_screen.dart';
import 'package:daily_you/utils/duration_format.dart';
import 'package:daily_you/widgets/expressive_icon_button.dart';
import 'package:material_ui/material_ui.dart';

class MediaPlaybackControls extends StatefulWidget {
  const MediaPlaybackControls({
    super.key,
    required this.position,
    required this.duration,
    required this.playing,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final ValueChanged<Duration> onSeek;

  @override
  State<MediaPlaybackControls> createState() => _MediaPlaybackControlsState();
}

class _MediaPlaybackControlsState extends State<MediaPlaybackControls> {
  static const double _trackInset = 24;
  static const double _inlineButtonSize = 48;
  static const double _inlineButtonGap = 16;

  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final isWide = isWideScreen(context);
    final totalMs = widget.duration.inMilliseconds;
    final sliderMax = totalMs == 0 ? 1.0 : totalMs.toDouble();
    final positionMs = (_dragValue ?? widget.position.inMilliseconds.toDouble())
        .clamp(0, sliderMax)
        .toDouble();

    final playButton = ExpressiveIconButton(
      icon: widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      squared: widget.playing,
      size: isWide ? _inlineButtonSize : ExpressiveIconButton.defaultSize,
      onPressed: widget.playing ? widget.onPause : widget.onPlay,
    );
    final slider = _buildSlider(context, positionMs, sliderMax);
    final labels = _buildTimeLabels(context, positionMs);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_trackInset, 12, _trackInset, 0),
          child: isWide
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        playButton,
                        const SizedBox(width: _inlineButtonGap),
                        Expanded(child: slider),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: _inlineButtonSize + _inlineButtonGap),
                      child: labels,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    slider,
                    labels,
                    const SizedBox(height: 8),
                    playButton,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSlider(
      BuildContext context, double positionMs, double sliderMax) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 16,
        trackGap: 6,
        trackShape: const GappedSliderTrackShape(),
        thumbShape: const HandleThumbShape(),
        padding: EdgeInsets.zero,
      ),
      child: Slider(
        // ignore: deprecated_member_use
        year2023: false,
        value: positionMs,
        max: sliderMax,
        semanticFormatterCallback: (value) =>
            formatDuration(Duration(milliseconds: value.round())),
        onChanged: (value) => setState(() => _dragValue = value),
        onChangeEnd: (value) {
          widget.onSeek(Duration(milliseconds: value.round()));
          setState(() => _dragValue = null);
        },
      ),
    );
  }

  Widget _buildTimeLabels(BuildContext context, double positionMs) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(formatDuration(Duration(milliseconds: positionMs.round())),
            style: labelStyle),
        Text(formatDuration(widget.duration), style: labelStyle),
      ],
    );
  }
}
