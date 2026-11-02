// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/learning_progress.dart';
import 'package:daily_you/models/practice_history.dart';
import 'package:daily_you/providers/learning_progress_provider.dart';
import 'package:daily_you/widgets/learning_reminder_dialog.dart';
import 'package:daily_you/widgets/weekly_progress_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Màn hình Tổng quan Tiến độ Học tập (Checklist 6 - TV3).
///
/// Dashboard hiển thị trực quan các chỉ số do TV2 cung cấp:
/// Streak ngọn lửa, Vòng tròn tiến độ mục tiêu, Thống kê thời gian học,
/// Biểu đồ tuần và Lịch sử bài luyện tập.
class LearningProgressPage extends StatefulWidget {
  final VoidCallback? onStartPractice;

  const LearningProgressPage({
    super.key,
    this.onStartPractice,
  });

  @override
  State<LearningProgressPage> createState() => _LearningProgressPageState();
}

class _LearningProgressPageState extends State<LearningProgressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LearningProgressProvider>();
      if (provider.state == ProgressViewState.initial) {
        provider.loadProgress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LearningProgressProvider>();
    final progress = provider.progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiến độ học tập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Cài đặt nhắc nhở & mục tiêu',
            onPressed: () => LearningReminderDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: _buildBody(context, provider, progress),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LearningProgressProvider provider,
    DailyLearningProgress progress,
  ) {
    // 1. Trạng thái Loading
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu tiến độ học tập...'),
          ],
        ),
      );
    }

    // 2. Trạng thái Lỗi
    if (provider.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'Đã xảy ra lỗi tải dữ liệu',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                onPressed: () => provider.refresh(),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Trạng thái Người dùng mới (Empty State)
    if (provider.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildEmptyStateCard(context),
            const SizedBox(height: 24),
            _buildStreakCard(context, progress),
          ],
        ),
      );
    }

    // 4. Trạng thái Đầy đủ dữ liệu (Loaded State)
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // 1. Card Streak ngọn lửa
          _buildStreakCard(context, progress),
          const SizedBox(height: 16),

          // 2. Card Vòng tròn tiến độ mục tiêu ngày
          _buildGoalProgressCard(context, progress),
          const SizedBox(height: 16),

          // 3. Grid 3 chỉ số thống kê nhanh
          _buildQuickStatsRow(context, progress),
          const SizedBox(height: 16),

          // 4. Card Biểu đồ học tập 7 ngày trong tuần
          _buildWeeklyChartCard(context, progress),
          const SizedBox(height: 16),

          // 5. Danh sách phiên học gần đây
          _buildRecentSessionsCard(context, progress),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Card Chuỗi ngày học liên tiếp (Streak).
  Widget _buildStreakCard(
      BuildContext context, DailyLearningProgress progress) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final streak = progress.streakCount;
    final message = _getStreakMessage(streak);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF7C2D12), const Color(0xFFC2410C)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Icon Ngọn lửa với viền tỏa sáng
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF97316).withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFF97316),
                width: 2,
              ),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),

          // Thông tin Streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$streak Ngày',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color:
                            isDark ? Colors.orange[200] : const Color(0xFFC2410C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C)
                            .withValues(alpha: isDark ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Kỷ lục: ${progress.longestStreak} ngày',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.orange[100]
                              : const Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? Colors.orange[100] : const Color(0xFF7C2D12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card Vòng tròn tiến độ mục tiêu học tập (Circular Progress Indicator).
  Widget _buildGoalProgressCard(
      BuildContext context, DailyLearningProgress progress) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAchieved = progress.isGoalAchieved;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mục tiêu học hôm nay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('${progress.dailyGoalMinutes} phút/ngày'),
                  onPressed: () => LearningReminderDialog.show(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Vòng tròn tiến độ Circular Progress
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress.progressPercentage / 100.0,
                        strokeWidth: 9,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAchieved
                              ? const Color(0xFF10B981) // Emerald Green
                              : theme.colorScheme.primary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isAchieved)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 24)
                          else
                            Text(
                              '${progress.progressPercentage.toInt()}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            isAchieved ? 'Đạt' : 'Mục tiêu',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Diễn giải và Nút kêu gọi hành động
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${progress.todayStudyMinutes} / ${progress.dailyGoalMinutes} phút',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAchieved
                            ? '🎉 Xuất sắc! Bạn đã hoàn thành mục tiêu học tập ngày hôm nay!'
                            : 'Còn ${progress.remainingMinutesToGoal} phút nữa để chạm mục tiêu hôm nay.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isAchieved
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.75),
                          fontWeight:
                              isAchieved ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.mic_rounded, size: 18),
                        label: const Text('Luyện phát âm ngay'),
                        onPressed: widget.onStartPractice ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đang mở phiên luyện phát âm AI (TV4 - Checklist 3)...',
                                  ),
                                ),
                              );
                            },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Grid 3 thẻ thống kê nhanh (Quick Stats).
  Widget _buildQuickStatsRow(
      BuildContext context, DailyLearningProgress progress) {
    final theme = Theme.of(context);

    final scoreText = progress.averagePronunciationScore != null
        ? '${progress.averagePronunciationScore!.toStringAsFixed(0)}/100'
        : '--';

    return Row(
      children: [
        _buildStatCard(
          context,
          icon: Icons.timer_outlined,
          iconColor: Colors.blueAccent,
          title: 'Học hôm nay',
          value: '${progress.todayStudyMinutes} phút',
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          context,
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Hoàn thành',
          value: '${progress.completedSessionsCount} bài',
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          context,
          icon: Icons.grade_outlined,
          iconColor: Colors.amber,
          title: 'Điểm phát âm',
          value: scoreText,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card Biểu đồ 7 ngày trong tuần.
  Widget _buildWeeklyChartCard(
      BuildContext context, DailyLearningProgress progress) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: WeeklyProgressChart(
          weeklyData: progress.weeklyProgress,
          dailyGoalMinutes: progress.dailyGoalMinutes,
        ),
      ),
    );
  }

  /// Danh sách các phiên luyện tập gần đây.
  Widget _buildRecentSessionsCard(
      BuildContext context, DailyLearningProgress progress) {
    final theme = Theme.of(context);
    final sessions = progress.recentSessions;

    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch sử luyện tập gần đây',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${sessions.length} bài gần nhất',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final s = sessions[index];
                return _buildSessionTile(context, s);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, PracticeHistory session) {
    final theme = Theme.of(context);
    final durationMin = (session.durationSeconds ?? 0) ~/ 60;
    final durationSec = (session.durationSeconds ?? 0) % 60;
    final durationStr = durationMin > 0
        ? '$durationMin phút $durationSec giây'
        : '$durationSec giây';

    final isCompleted = session.status == PracticeStatus.completed;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getActivityIcon(session.activityType),
            color: isCompleted ? const Color(0xFF10B981) : Colors.amber,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${session.practiceDate} • $durationStr',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isCompleted ? 'Hoàn thành' : 'Chưa xong',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCompleted ? const Color(0xFF047857) : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  /// Giao diện chào đón khi người dùng chưa có dữ liệu học tập.
  Widget _buildEmptyStateCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Bắt đầu hành trình phát âm AI!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn chưa có phiên luyện tập nào. Hãy bắt đầu bài luyện phát âm đầu tiên ngay bây giờ để kích hoạt chuỗi học tập và mở khóa các huy hiệu nhé!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Bắt đầu bài học đầu tiên'),
            onPressed: widget.onStartPractice ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Khởi tạo bài học đầu tiên...'),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.pronunciation:
        return Icons.mic_rounded;
      case ActivityType.speaking:
        return Icons.record_voice_over_rounded;
      case ActivityType.listening:
        return Icons.headphones_rounded;
      case ActivityType.vocabulary:
        return Icons.menu_book_rounded;
      case ActivityType.reading:
        return Icons.auto_stories_rounded;
      case ActivityType.other:
      default:
        return Icons.school_rounded;
    }
  }

  String _getStreakMessage(int streak) {
    if (streak == 0) return 'Luyện tập hôm nay để thắp sáng ngọn lửa!';
    if (streak == 1) return 'Khởi đầu tuyệt vời! Hãy duy trì ngày mai nhé.';
    if (streak < 5) return 'Phong độ xuất sắc! Ngọn lửa đang bùng cháy!';
    return 'Chiến binh kiên trì! Chuỗi ngày học tập đáng tự hào! 🏆';
  }
}
