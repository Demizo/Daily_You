import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/connected_button_group.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.statisticsRangeOneMonth,
      l10n.statisticsRangeSixMonths,
      l10n.statisticsRangeOneYear,
      l10n.statisticsRangeAllTime,
    ];
    final ranges = [
      StatsRange.month,
      StatsRange.sixMonths,
      StatsRange.year,
      StatsRange.allTime,
    ];

    return ConnectedButtonGroup(
      labels: labels,
      selectedIndex: ranges.indexOf(statsRange),
      onSelectionChanged: (i) {
        setState(() {
          statsRange = ranges[i];
        });
        widget.onSelectionChanged(ranges[i]);
      },
    );
  }
}
