import 'package:daily_you/stats_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum StatsRange { month, sixMonths, year, allTime }

class StatsRangeSelector extends StatefulWidget {
  final Function(Set<StatsRange> newSelection) onSelectionChanged;
  const StatsRangeSelector({super.key, required this.onSelectionChanged});

  @override
  State<StatsRangeSelector> createState() => _StatsRangeSelectorState();
}

class _StatsRangeSelectorState extends State<StatsRangeSelector> {
  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
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
      selected: <StatsRange>{statsProvider.statsRange},
      onSelectionChanged: (Set<StatsRange> newSelection) {
        setState(() {
          statsProvider.statsRange = newSelection.first;
          StatsProvider.instance.updateStats();
        });
        widget.onSelectionChanged(newSelection);
      },
    );
  }
}
