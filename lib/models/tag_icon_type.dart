// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

enum TagIconType {
  character,
  materialIcon;

  int toInt() => index;

  static TagIconType fromInt(int? value) =>
      value == null ? TagIconType.character : TagIconType.values[value];
}
