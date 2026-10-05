// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class FileSizeRow extends StatelessWidget {
  const FileSizeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.sizeText,
  });

  final IconData icon;
  final String label;
  final String sizeText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 12),
        Text(sizeText, style: TextStyle(color: colors.onSurfaceVariant)),
      ],
    );
  }
}
