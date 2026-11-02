// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/learning_progress.dart';
import 'package:material_ui/material_ui.dart';

/// Widget biểu đồ cột hiển thị tiến độ học tập 7 ngày gần nhất (Weekly Progress Chart).
class WeeklyProgressChart extends StatelessWidget {
  final WeeklyProgressData weeklyData;
  final int dailyGoalMinutes;

  const WeeklyProgressChart({
    super.key,
    required this.weeklyData,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (weeklyData.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Chưa có dữ liệu tuần này',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    // Tìm giá trị lớn nhất để chuẩn hóa chiều cao cột
    final maxMinutes = weeklyData.days
        .map((d) => d.studyMinutes)
        .fold<int>(dailyGoalMinutes, (prev, m) => m > prev ? m : prev);

    final normalizedMax = maxMinutes > 0 ? maxMinutes : 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề thống kê nhanh tuần
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng tuần: ${weeklyData.totalWeekMinutes} phút',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'TB: ${weeklyData.averageDailyMinutes.toStringAsFixed(1)} phút/ngày',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            if (weeklyData.bestDay != null &&
                weeklyData.bestDay!.studyMinutes > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Cao nhất: ${weeklyData.bestDay!.dayOfWeekLabel} (${weeklyData.bestDay!.studyMinutes}p)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber[200] : Colors.amber[900],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Khung các cột biểu đồ
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weeklyData.days.map((day) {
              final isToday = _isToday(day.date);
              final isAchieved = day.isGoalAchieved;
              final heightFactor =
                  (day.studyMinutes / normalizedMax).clamp(0.05, 1.0);

              // Màu sắc thanh cột
              final Color barColor = isAchieved
                  ? const Color(0xFF10B981) // Emerald Green
                  : (day.studyMinutes > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Số phút trên đỉnh cột
                      Text(
                        day.studyMinutes > 0 ? '${day.studyMinutes}p' : '-',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Cột biểu đồ với hiệu ứng bo tròn
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: heightFactor,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              border: isToday
                                  ? Border.all(
                                      color: Colors.amber,
                                      width: 2.0,
                                    )
                                  : null,
                              boxShadow: isAchieved
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nhãn ngày (T2, T3, ... CN)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: isToday
                            ? BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              )
                            : null,
                        child: Text(
                          day.dayOfWeekLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
