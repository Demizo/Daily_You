// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/study_sentence_dao.dart';
import 'package:daily_you/models/study_sentence.dart';
import 'package:daily_you/providers/user_session_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Hộp thoại cho phép học viên tự tạo câu tiếng Anh mới để luyện tập.
class AddSentenceDialog extends StatefulWidget {
  final String? initialTopic;

  const AddSentenceDialog({super.key, this.initialTopic});

  static Future<StudySentence?> show(
    BuildContext context, {
    String? initialTopic,
  }) {
    return showDialog<StudySentence>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddSentenceDialog(initialTopic: initialTopic),
    );
  }

  @override
  State<AddSentenceDialog> createState() => _AddSentenceDialogState();
}

class _AddSentenceDialogState extends State<AddSentenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sentenceController = TextEditingController();
  final _meaningController = TextEditingController();
  final _ipaController = TextEditingController();
  late String _selectedTopic;
  bool _isSaving = false;

  final Map<String, String> _topics = {
    'daily': '☕ Giao tiếp',
    'travel': '✈️ Du lịch',
    'work': '💼 Công sở',
    'dining': '🍔 Ẩm thực',
    'custom': '⭐ Cá nhân',
  };

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.initialTopic ?? 'daily';
    if (!_topics.containsKey(_selectedTopic)) {
      _selectedTopic = 'daily';
    }
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _meaningController.dispose();
    _ipaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final session = context.read<UserSessionProvider>();
      final currentUserId = session.currentUserId;

      final newSentence = await StudySentenceDao.add(StudySentence(
        userId: currentUserId,
        topic: _selectedTopic,
        sentence: _sentenceController.text.trim(),
        meaning: _meaningController.text.trim(),
        ipa: _ipaController.text.trim().isNotEmpty
            ? _ipaController.text.trim()
            : null,
        timeCreate: DateTime.now(),
      ));

      if (mounted) {
        Navigator.of(context).pop(newSentence);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thêm câu: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_comment_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thêm câu luyện tập mới',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Chọn chủ đề
                Text(
                  'CHỌN CHỦ ĐỀ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _topics.entries.map((entry) {
                    final isSelected = _selectedTopic == entry.key;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _selectedTopic = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Ô nhập câu tiếng Anh
                TextFormField(
                  controller: _sentenceController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Câu tiếng Anh cần luyện *',
                    hintText: 'Ví dụ: Could you please help me with this?',
                    prefixIcon: Icon(Icons.translate_rounded),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập câu tiếng Anh';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Ô nhập nghĩa tiếng Việt
                TextFormField(
                  controller: _meaningController,
                  decoration: const InputDecoration(
                    labelText: 'Nghĩa tiếng Việt *',
                    hintText: 'Ví dụ: Bạn có thể giúp tôi việc này được không?',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập nghĩa tiếng Việt';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Ô nhập phiên âm IPA (tùy chọn)
                TextFormField(
                  controller: _ipaController,
                  decoration: const InputDecoration(
                    labelText: 'Phiên âm IPA (Tùy chọn)',
                    hintText: 'Ví dụ: /kʊd juː pliːz help miː wɪð ðɪs/',
                    prefixIcon: Icon(Icons.record_voice_over_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 18),

                // Nút Lưu
                FilledButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving
                      ? 'Đang lưu...'
                      : 'Lưu vào danh sách luyện tập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

