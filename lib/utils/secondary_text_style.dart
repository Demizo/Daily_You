// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

TextStyle secondaryTextStyle(BuildContext context, {double? fontSize}) =>
    TextStyle(
      fontSize: fontSize,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
