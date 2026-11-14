// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

Set<T> toggledSelection<T>(Set<T> selection, T value) =>
    selection.contains(value)
        ? (selection.toSet()..remove(value))
        : {...selection, value};
