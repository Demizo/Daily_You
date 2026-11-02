// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/providers/learning_progress_provider.dart';
import 'package:daily_you/services/daily_reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hộp thoại Cài đặt Nhắc nhở và Mục tiêu học tập (Checklist 6 - TV3).
class LearningReminderDialog extends StatefulWidget {
  const LearningReminderDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LearningReminderDialog(),
    );
  }

  @override
  State<LearningReminderDialog> createState() => _LearningReminderDialogState();
}

class _LearningReminderDialogState extends State<LearningReminderDialog> {
  final _service = DailyReminderService();

  bool _isLoading = true;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  int _dailyGoalMinutes = 20;
  bool _onlyIfPending = true;

  final List<int> _goalOptions = [10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _service.isReminderEnabled();
    final time = await _service.getReminderTime();
    final goal = await _service.getDailyGoalMinutes();
    final onlyIfPending = await _service.isOnlyIfPending();

    if (mounted) {
      setState(() {
        _reminderEnabled = enabled;
        _reminderTime = time;
        _dailyGoalMinutes = goal;
        _onlyIfPending = onlyIfPending;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _saveSettings() async {
    final progressProvider = context.read<LearningProgressProvider>();

    // 1. Cập nhật mục tiêu
    await progressProvider.updateDailyGoal(_dailyGoalMinutes);
    await _service.setOnlyIfPending(_onlyIfPending);

    // 2. Lập lịch hoặc hủy nhắc nhở
    if (_reminderEnabled) {
      final hasPermission = await _service.requestNotificationPermissions();
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Vui lòng cấp quyền thông báo trong Cài đặt máy để nhận nhắc nhở!',
            ),
          ),
        );
      }
      await _service.scheduleDailyReminder(time: _reminderTime);
    } else {
      await _service.cancelDailyReminder();
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu cài đặt nhắc nhở & mục tiêu thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    await _service.sendTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Đã bắn thông báo thử nghiệm tới khay hệ thống!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cài đặt Nhắc học & Mục tiêu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mục tiêu học tập hằng ngày
                  Text(
                    'Mục tiêu học mỗi ngày',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số phút luyện phát âm bạn muốn đạt được mỗi ngày',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _goalOptions.map((minutes) {
                      final isSelected = _dailyGoalMinutes == minutes;
                      return ChoiceChip(
                        label: Text('$minutes phút'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _dailyGoalMinutes = minutes);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const Divider(height: 28),

                  // Bật/tắt thông báo nhắc học
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Bật nhắc nhở hằng ngày',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Nhắc bạn vào học đúng giờ mỗi ngày'),
                    value: _reminderEnabled,
                    onChanged: (val) {
                      setState(() => _reminderEnabled = val);
                    },
                  ),

                  if (_reminderEnabled) ...[
                    const SizedBox(height: 8),

                    // Chọn giờ nhắc nhở
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Giờ nhắc nhở'),
                      trailing: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(
                          '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _pickTime,
                      ),
                    ),

                    // Tùy chọn chỉ nhắc khi chưa hoàn thành mục tiêu
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Chỉ nhắc khi chưa hoàn thành mục tiêu',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Không làm phiền nếu bạn đã hoàn thành bài học hôm nay',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _onlyIfPending,
                      onChanged: (val) {
                        setState(() => _onlyIfPending = val ?? true);
                      },
                    ),

                    const SizedBox(height: 8),

                    // Nút bắn thông báo thử nghiệm
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Bắn thông báo thử nghiệm ngay'),
                        onPressed: _sendTestNotification,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: const Text('Lưu cài đặt'),
        ),
      ],
    );
  }
}
