import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

enum StatsRange { month, sixMonths, year, allTime }

class StatsRangeSelector extends StatefulWidget {
  final StatsRange statsRange;
  final Function(StatsRange newSelection) onSelectionChanged;
  const StatsRangeSelector(
      {super.key, required this.statsRange, required this.onSelectionChanged});

  @override
  State<StatsRangeSelector> createState() => _StatsRangeSelectorState();
}

class _StatsRangeSelectorState extends State<StatsRangeSelector> {
  late StatsRange statsRange;

  @override
  void initState() {
    super.initState();
    statsRange = widget.statsRange;
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsRange>(
      showSelectedIcon: false,
      segments: <ButtonSegment<StatsRange>>[
        ButtonSegment<StatsRange>(
          value: StatsRange.month,
          label: Text(AppLocalizations.of(context)!.statisticsRangeOneMonth),
        ),
        ButtonSegment<StatsRange>(
          value: StatsRange.sixMonths,
          label: Text(AppLocalizations.of(context)!.statisticsRangeSixMonths),
        ),
        ButtonSegment<StatsRange>(
          value: StatsRange.year,
          label: Text(AppLocalizations.of(context)!.statisticsRangeOneYear),
        ),
        ButtonSegment<StatsRange>(
          value: StatsRange.allTime,
          label: Text(AppLocalizations.of(context)!.statisticsRangeAllTime),
        ),
      ],
      selected: <StatsRange>{statsRange},
      onSelectionChanged: (Set<StatsRange> newSelection) {
        setState(() {
          statsRange = newSelection.first;
        });
        widget.onSelectionChanged(newSelection.first);
      },
    );
  }
}
