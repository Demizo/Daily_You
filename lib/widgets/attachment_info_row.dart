// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class AttachmentInfoRow extends StatelessWidget {
  const AttachmentInfoRow({super.key, required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).disabledColor),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }
}
