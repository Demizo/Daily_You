// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';

extension SyncItemPresentation on SyncItem {
  String label(AppLocalizations l10n) =>
      attachmentType?.label(l10n) ?? l10n.settingsLogFolder;
}
