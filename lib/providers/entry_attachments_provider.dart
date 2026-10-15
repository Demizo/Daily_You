// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_attachment_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:material_ui/material_ui.dart';

class EntryAttachmentsProvider with ChangeNotifier {
  static final EntryAttachmentsProvider instance =
      EntryAttachmentsProvider._init();

  EntryAttachmentsProvider._init();

  List<EntryAttachment> attachments = List.empty(growable: true);
  Map<int, List<EntryAttachment>> _coverCandidatesByEntryId = {};

  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  @visibleForTesting
  set isLoaded(bool value) => _isLoaded = value;

  static bool _isCoverCandidate(EntryAttachment attachment) =>
      attachment.type.isVisual;

  void _rebuildCache() {
    final cache = <int, List<EntryAttachment>>{};
    for (final attachment in attachments) {
      if (!_isCoverCandidate(attachment)) continue;
      final id = attachment.entryId;
      if (id == null) continue;
      cache.putIfAbsent(id, () => []).add(attachment);
    }
    for (final candidates in cache.values) {
      candidates.sort((a, b) => b.rank.compareTo(a.rank));
    }
    _coverCandidatesByEntryId = cache;
  }

  void _addToCache(EntryAttachment attachment) {
    final id = attachment.entryId;
    if (id == null || !_isCoverCandidate(attachment)) return;
    _coverCandidatesByEntryId[id] = [
      ...?_coverCandidatesByEntryId[id],
      attachment,
    ]..sort((a, b) => b.rank.compareTo(a.rank));
  }

  Future<void> load() async {
    attachments = await EntryAttachmentDao.getAll();
    _rebuildCache();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> add(EntryAttachment attachment, {skipUpdate = false}) async {
    final attachmentWithId = await EntryAttachmentDao.add(attachment);
    attachments.add(attachmentWithId);
    _addToCache(attachmentWithId);
    await AppDatabase.instance.updateExternalDatabase();
    if (!skipUpdate) {
      notifyListeners();
    }
  }

  Future<void> remove(EntryAttachment attachment) async {
    await EntryAttachmentDao.remove(attachment);
    attachments.removeWhere((x) => x.id == attachment.id);
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> update(EntryAttachment attachment) async {
    await EntryAttachmentDao.update(attachment);
    final index = attachments.indexWhere((x) => x.id == attachment.id);
    attachments[index] = attachment;
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  void applyForEntry(int entryId, List<EntryAttachment> written) {
    attachments = [
      ...attachments.where((attachment) => attachment.entryId != entryId),
      ...written,
    ];
    _rebuildCache();
    notifyListeners();
  }

  List<EntryAttachment> getCoverCandidatesForEntry(int entryId) =>
      _coverCandidatesByEntryId[entryId] ?? const [];

  List<EntryAttachment> getForEntry(Entry entry) {
    final attachmentsForEntry = attachments
        .where((attachment) => attachment.entryId == entry.id!)
        .toList();
    attachmentsForEntry.sort((a, b) => b.rank.compareTo(a.rank));
    return attachmentsForEntry;
  }
}
