// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

String titledText(String? title, String? text) => [
      if (title != null && title.isNotEmpty) '# $title',
      if (text != null && text.isNotEmpty) text,
    ].join('\n\n');
