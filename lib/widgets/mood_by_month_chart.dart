import 'package:daily_you/models/entry.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MoodByMonthChart extends StatefulWidget {
  const MoodByMonthChart({super.key});

  @override
  State<MoodByMonthChart> createState() => _MoodByMonthChartState();
}

class _MoodByMonthChartState extends State<MoodByMonthChart> {
  Map<String, double?> averageMood = {};
  late List<String> sortedKeys;
  int currentPage = 0;
  int monthsPerPage = 12;
  bool notEnoughData = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Entry> entries = StatsProvider.instance.entries;
    Map<String, List<double>> moodsByMonth = {};

    // Collect moods by month
    for (Entry entry in entries) {
      if (entry.mood == null) continue;
      String monthKey =
          "${entry.timeCreate.year}-${entry.timeCreate.month.toString().padLeft(2, '0')}";
      if (moodsByMonth[monthKey] != null) {
        moodsByMonth[monthKey]!.add(entry.mood!.toDouble());
      } else {
        moodsByMonth[monthKey] = List.empty(growable: true);
        moodsByMonth[monthKey]!.add(entry.mood!.toDouble());
      }
    }

    // Average the mood for each month
    averageMood.clear();
    for (var month in moodsByMonth.keys) {
      averageMood[month] = moodsByMonth[month]!.reduce((a, b) => a + b) /
          moodsByMonth[month]!.length;
    }

    // Ensure there is enough data
    notEnoughData = averageMood.length < 2;

    // Fill in empty months
    sortedKeys = averageMood.keys.toList()..sort();
    var allMonths = _generateCompleteMonthRange(sortedKeys, monthsPerPage);
    sortedKeys = allMonths.toList()..sort();

    // Determine the subset of data for the current page
    int endIndex = (sortedKeys.length - (currentPage * monthsPerPage))
        .clamp(0, sortedKeys.length);
    int startIndex = (endIndex - monthsPerPage).clamp(0, endIndex);
    // Ensure page is full if possible
    int currentPageSize = endIndex - startIndex;
    if (currentPageSize < monthsPerPage) {
      endIndex = (endIndex + (monthsPerPage - currentPageSize))
          .clamp(0, sortedKeys.length);
    }

    List<String> currentPageKeys = sortedKeys.sublist(startIndex, endIndex);

    Map<String, double?> currentData = {
      for (var key in currentPageKeys) key: averageMood[key]
    };

    return Center(
      child: notEnoughData
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: AspectRatio(
                aspectRatio: 2,
                child: Card(
                    child: Center(
                        child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      size: 100,
                      color: Theme.of(context).disabledColor,
                    ),
                    Text(
                      AppLocalizations.of(context)!.statisticsNotEnoughData,
                      style: TextStyle(
                          fontSize: 18, color: Theme.of(context).disabledColor),
                    )
                  ],
                ))),
              ),
            )
          : Column(
              children: [
                _buildPaginationControls(currentPageKeys, context),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 0, right: 42, bottom: 0, top: 8),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: LineChart(_buildLineChartData(
                        Theme.of(context).colorScheme.primary,
                        currentData,
                        currentPageKeys,
                        context)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaginationControls(List<String> keys, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_totalPages() > 1)
          IconButton(
            onPressed: currentPage < _totalPages() - 1 ? _goToNextPage : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        Text(
            "${_formatMonthYear(keys.first, context)} - ${_formatMonthYear(keys.last, context)}"),
        if (_totalPages() > 1)
          IconButton(
            onPressed: currentPage > 0 ? _goToPreviousPage : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
          ),
      ],
    );
  }

  int _totalPages() {
    return (sortedKeys.length / monthsPerPage).ceil();
  }

  void _goToPreviousPage() {
    setState(() {
      currentPage--;
    });
  }

  void _goToNextPage() {
    setState(() {
      currentPage++;
    });
  }

  LineChartData _buildLineChartData(Color color, Map<String, double?> data,
      List<String> keys, BuildContext context) {
    List<FlSpot?> spots = keys.asMap().entries.map((entry) {
      int index = entry.key;
      String key = entry.value;
      double? mood = data[key];

      return mood != null ? FlSpot(index.toDouble(), mood) : null;
    }).toList();

    return LineChartData(
      minX: 0,
      maxX: keys.length - 1.toDouble(),
      minY: -2,
      maxY: 2,
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        if (spots.whereType<FlSpot>().toList().isNotEmpty)
          LineChartBarData(
            spots: spots.whereType<FlSpot>().toList(),
            isCurved: false,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (p0, p1, p2, p3) {
                return FlDotCirclePainter(color: color, radius: 6);
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
      ],
      titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_formatMonth(
                  value >= 0 && value < keys.length ? keys[value.toInt()] : '',
                  context)),
            ),
            interval: 1,
            reservedSize: 36,
          )),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: MoodIcon(
                      moodValue: index,
                    ));
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles()),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        horizontalInterval: 1,
        drawVerticalLine: true,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.symmetric(
              horizontal: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            width: 1,
          ))),
    );
  }

  String _formatMonth(String dateKey, BuildContext context) {
    DateTime date = DateFormat('yyyy-MM').parse(dateKey);
    return DateFormat(
            'MMM', WidgetsBinding.instance.platformDispatcher.locale.toString())
        .format(date); // Return shorthand month (e.g., "Jan")
  }

  String _formatMonthYear(String dateKey, BuildContext context) {
    DateTime date = DateFormat('yyyy-MM').parse(dateKey);
    return DateFormat('MMM yyyy',
            WidgetsBinding.instance.platformDispatcher.locale.toString())
        .format(date); // Return shorthand month (e.g., "Jan")
  }

  List<String> _generateCompleteMonthRange(
      Iterable<String> keys, int monthsPerPage) {
    if (keys.isEmpty) {
      return List.empty();
    }

    List<DateTime> parsedDates =
        keys.map((key) => DateFormat('yyyy-MM').parse(key)).toList()..sort();

    DateTime startDate = parsedDates.first;
    DateTime endDate = parsedDates.last;

    // Start chart on left side if page can't be filled
    DateTime minEndDate = DateTime(
        startDate.year, startDate.month + (monthsPerPage - 1), startDate.day);
    if (endDate.isBefore(minEndDate)) {
      endDate = minEndDate;
    }

    List<String> allMonths = [];
    DateTime current = startDate;

    while (!current.isAfter(endDate)) {
      String monthKey =
          "${current.year}-${current.month.toString().padLeft(2, '0')}";
      allMonths.add(monthKey);
      current = DateTime(current.year, current.month + 1);
    }

    return allMonths;
  }
}
