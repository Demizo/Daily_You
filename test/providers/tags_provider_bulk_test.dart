// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/export_harness.dart';

void main() {
  final harness = ExportHarness();
  useExportHarness(harness);

  final provider = TagsProvider.instance;

  late Tag walk;
  late Tag water;
  late Tag read;
  late Entry first;
  late Entry second;
  late Entry third;

  setUp(() async {
    walk = await harness.addTag('Walk', TagType.label);
    water = await harness.addTag('Water', TagType.tracker);
    read = await harness.addTag('Read', TagType.label);
    first = await harness.addEntry(DateTime(2026, 3, 1),
        tags: [SeededTag(walk), SeededTag(water, value: '2')]);
    second = await harness.addEntry(DateTime(2026, 3, 2),
        tags: [SeededTag(walk), SeededTag(read)]);
    third = await harness.addEntry(DateTime(2026, 3, 3));
  });

  Set<int> tagIdsOf(Entry entry) => {
        for (final entryTag in provider.getEntryTagsForEntry(entry.id!))
          entryTag.tagId
      };

  test('reports whether a tag is on all, some or none of the logs', () {
    final presence = provider.tagPresenceFor({first.id!, second.id!});

    expect(presence[walk.id], TagPresence.all);
    expect(presence[water.id], TagPresence.some);
    expect(presence[read.id], TagPresence.some);
    expect(presence.containsKey(99), isFalse);
    expect(provider.tagPresenceFor({third.id!}), isEmpty);
  });

  test('adds a label to every log that lacks it', () async {
    final everyEntry = {first.id!, second.id!, third.id!};

    await provider.applyTagChanges(everyEntry, additions: {read.id!: null});

    for (final entry in [first, second, third]) {
      expect(tagIdsOf(entry), contains(read.id));
    }
    expect(provider.tagPresenceFor(everyEntry)[read.id], TagPresence.all);
  });

  test('adds a tracker value only to logs without it', () async {
    await provider.applyTagChanges({first.id!, second.id!, third.id!},
        additions: {water.id!: '5'});

    String? valueOf(Entry entry) => provider
        .getEntryTagsForEntry(entry.id!)
        .where((entryTag) => entryTag.tagId == water.id)
        .single
        .value;
    expect(valueOf(first), '2');
    expect(valueOf(second), '5');
    expect(valueOf(third), '5');
  });

  test('removes a tag from every log that has it', () async {
    await provider.applyTagChanges({first.id!, second.id!, third.id!},
        removals: {walk.id!});

    expect(tagIdsOf(first), {water.id});
    expect(tagIdsOf(second), {read.id});
    expect(tagIdsOf(third), isEmpty);
  });

  test('leaves tags that were not changed alone', () async {
    await provider.applyTagChanges({first.id!, second.id!},
        additions: {read.id!: null}, removals: {walk.id!});

    expect(tagIdsOf(first), {water.id, read.id});
    expect(tagIdsOf(second), {read.id});
    expect(provider.getEntryTagsForEntry(first.id!).length, 2);
  });

  test('leaves logs outside the selection alone', () async {
    await provider.applyTagChanges({first.id!}, removals: {walk.id!});

    expect(tagIdsOf(second), {walk.id, read.id});
  });

  test('persists the changes and notifies once', () async {
    var notifications = 0;
    void listener() => notifications += 1;
    provider.addListener(listener);

    await provider.applyTagChanges({first.id!, second.id!, third.id!},
        additions: {read.id!: null}, removals: {walk.id!});
    provider.removeListener(listener);
    await harness.reloadProviders();

    expect(notifications, 1);
    expect(tagIdsOf(first), {water.id, read.id});
    expect(tagIdsOf(third), {read.id});
  });

  test('does not notify when nothing changes', () async {
    var notifications = 0;
    void listener() => notifications += 1;
    provider.addListener(listener);

    await provider.applyTagChanges({third.id!}, removals: {walk.id!});
    provider.removeListener(listener);

    expect(notifications, 0);
  });
}
